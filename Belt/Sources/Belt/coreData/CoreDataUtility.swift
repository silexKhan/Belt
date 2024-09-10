//
//  CoreDataUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

import Foundation
import CoreData
import Combine

/// A utility class to handle common Core Data operations with support for Combine framework for asynchronous tasks.
/// This class provides functionalities such as creating, fetching, deleting, and saving Core Data entities,
/// as well as handling batch updates, array storage, pagination, and background task processing.
///
/// The class manages the Core Data stack via NSPersistentContainer and utilizes AnyPublisher to return the result of
/// asynchronous operations, allowing seamless error handling and chaining of tasks.
/// The class is designed to streamline the Core Data interaction process and encapsulate commonly used patterns.
///
/// # Usage Example:
///
/// ```swift
/// let coreDataUtility = CoreDataUtility(modelName: "MyModel")
///
/// // Creating an entity
/// let newEntity = coreDataUtility.createEntity(MyEntity.self)
/// newEntity.name = "Sample Name"
///
/// // Saving the context
/// coreDataUtility.saveContext()
///     .sink(receiveCompletion: { completion in
///         switch completion {
///         case .finished:
///             print("Save successful")
///         case .failure(let error):
///             print("Save failed: \(error)")
///         }
///     }, receiveValue: { success in
///         if success {
///             print("Changes were saved.")
///         } else {
///             print("No changes to save.")
///         }
///     })
///     .store(in: &cancellables)
///
/// // Fetching entities
/// let fetchRequest: NSFetchRequest<MyEntity> = MyEntity.fetchRequest()
/// coreDataUtility.fetchEntities(with: fetchRequest)
///     .sink(receiveCompletion: { completion in
///         if case .failure(let error) = completion {
///             print("Fetch failed: \(error)")
///         }
///     }, receiveValue: { entities in
///         print("Fetched \(entities.count) entities.")
///     })
///     .store(in: &cancellables)
///
/// // Deleting an entity
/// coreDataUtility.deleteEntity(newEntity)
///     .sink(receiveCompletion: { completion in
///         if case .failure(let error) = completion {
///             print("Delete failed: \(error)")
///         }
///     }, receiveValue: { success in
///         print("Entity deleted: \(success)")
///     })
///     .store(in: &cancellables)
/// ```
public class CoreDataUtility {
    
    private let persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext { persistentContainer.viewContext }
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the CoreDataUtility with the specified model name.
    /// Sets up the NSPersistentContainer and loads the persistent stores.
    /// - Parameter modelName: The name of the Core Data model.
    public init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }
    
    /// Saves the current state of the context if there are changes.
    /// - Returns: An `AnyPublisher<Bool, CoreDataError>` that emits `true` if changes were saved, `false` if no changes were present, or an error in case of failure.
    public func saveContext() -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            if self.context.hasChanges {
                do {
                    try self.context.save()
                    promise(.success(true))
                } catch {
                    promise(.failure(.saveError(error)))
                }
            } else {
                promise(.success(false))  // 변경 사항이 없는 경우
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Creates a new entity of the specified Core Data type.
    /// - Parameter entity: The type of the Core Data entity to create.
    /// - Returns: A new instance of the specified entity type.
    public func createEntity<T: NSManagedObject>(_ entity: T.Type) -> T {
        return T(context: context)
    }
    
    /// Fetches entities from the Core Data store using the provided fetch request.
    /// - Parameter fetchRequest: An `NSFetchRequest` object to specify the data to be fetched.
    /// - Returns: An `AnyPublisher<[T], CoreDataError>` that emits an array of entities or an error in case of failure.
    public func fetchEntities<T: NSManagedObject>(with fetchRequest: NSFetchRequest<T>) -> AnyPublisher<[T], CoreDataError> {
        return Future { promise in
            do {
                let result = try self.context.fetch(fetchRequest)
                promise(.success(result))
            } catch {
                promise(.failure(.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Deletes the specified entity from the context.
    /// - Parameter entity: The Core Data entity to be deleted.
    /// - Returns: An `AnyPublisher<Bool, CoreDataError>` that emits `true` if the entity was successfully deleted, or an error in case of failure.
    public func deleteEntity<T: NSManagedObject>(_ entity: T) -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            self.context.delete(entity)
            self.saveContext()
                .sink(receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                }, receiveValue: { success in
                    promise(.success(success))
                })
                .store(in: &self.cancellables)
        }
        .eraseToAnyPublisher()
    }
    
    /// Deletes all entities of the specified type from the Core Data store.
    /// - Parameter entity: The type of Core Data entity to delete.
    /// - Returns: An `AnyPublisher<Bool, CoreDataError>` that emits `true` if all entities were successfully deleted, or an error in case of failure.
    public func deleteAllEntities<T: NSManagedObject>(_ entity: T.Type) -> AnyPublisher<Bool, CoreDataError> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        return Future { promise in
            do {
                try self.context.execute(batchDeleteRequest)
                promise(.success(true))
            } catch {
                promise(.failure(.deleteError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Saves an array of encodable data into the specified entity's attribute.
    /// - Parameters:
    ///   - array: The array of encodable data to save.
    ///   - key: The key for the entity's attribute where the data will be stored.
    ///   - entityType: The Core Data entity type to store the data in.
    /// - Returns: An `AnyPublisher<Bool, CoreDataError>` that emits `true` if the array was successfully saved, or an error in case of failure.
    public func saveArray<T: Encodable>(_ array: [T], forKey key: String, entityType: NSManagedObject.Type) -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            do {
                let data = try JSONEncoder().encode(array)
                let entity = self.createEntity(entityType) // 외부에서 전달된 엔티티 타입 사용
                entity.setValue(data, forKey: key)
                try self.context.save()
                promise(.success(true))
            } catch {
                promise(.failure(.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    /// Fetches and decodes an array of data from a Core Data entity attribute.
    /// - Parameters:
    ///   - type: The type of data to decode from the stored data.
    ///   - key: The key for the entity's attribute where the data is stored.
    ///   - entity: The Core Data entity that holds the data.
    /// - Returns: An `AnyPublisher<[T], CoreDataError>` that emits the decoded array or an error in case of failure.
    public func fetchArray<T: Decodable>(_ type: T.Type, forKey key: String, from entity: NSManagedObject) -> AnyPublisher<[T], CoreDataError> {
        return Future { promise in
            guard let data = entity.value(forKey: key) as? Data else {
                promise(.success([]))  // 데이터가 없을 때 빈 배열 반환
                return
            }
            
            do {
                let array = try JSONDecoder().decode([T].self, from: data)
                promise(.success(array))
            } catch {
                promise(.failure(.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Performs a batch update on the specified Core Data entity type.
    /// - Parameters:
    ///   - entity: The type of Core Data entity to update.
    ///   - propertiesToUpdate: A dictionary of properties and their new values.
    /// - Returns: An `AnyPublisher<Bool, CoreDataError>` that emits `true` if the update was successful, or an error in case of failure.
    public func batchUpdateEntity<T: NSManagedObject>(_ entity: T.Type, propertiesToUpdate: [String: Any]) -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            let entityName = String(describing: entity)  // 엔티티 이름 가져오기
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchUpdateRequest = NSBatchUpdateRequest(entityName: entityName)
            batchUpdateRequest.resultType = .updatedObjectsCountResultType
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            
            do {
                let result = try self.context.execute(batchUpdateRequest) as? NSBatchUpdateResult
                let updatedCount = result?.result as? Int ?? 0
                print("\(updatedCount) records updated.")
                promise(.success(true))
            } catch {
                promise(.failure(.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Fetches a paginated list of entities from the Core Data store.
    /// - Parameters:
    ///   - fetchRequest: An `NSFetchRequest` object to specify the data to be fetched.
    ///   - limit: The number of entities to fetch.
    ///   - offset: The starting point of the data fetch.
    /// - Returns: An `AnyPublisher<[T], CoreDataError>` that emits an array of entities or an error in case of failure.
    public func fetchEntitiesWithPagination<T: NSManagedObject>(with fetchRequest: NSFetchRequest<T>, limit: Int, offset: Int) -> AnyPublisher<[T], CoreDataError> {
        return Future { promise in
            fetchRequest.fetchLimit = limit
            fetchRequest.fetchOffset = offset
            
            do {
                let result = try self.context.fetch(fetchRequest)
                promise(.success(result))
            } catch {
                promise(.failure(.fetchError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Executes a block of code on a background context.
    /// - Parameter block: A closure that contains the code to be executed on the background context.
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            block(backgroundContext)
            if backgroundContext.hasChanges {
                do {
                    try backgroundContext.save()
                } catch {
                    print("Error saving background context: \(error)")
                }
            }
        }
    }
}
