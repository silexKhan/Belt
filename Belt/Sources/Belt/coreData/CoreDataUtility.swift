//
//  CoreDataUtility.swift
//
//
//  Created by ahn kyu suk on 9/5/24.
//

/**
 CoreDataUtility 클래스는 iOS에서 Core Data와 관련된 작업을 간편하게 처리하기 위한 유틸리티 클래스입니다.
 데이터를 저장, 읽기, 삭제와 같은 기본적인 CRUD 작업을 지원하며, Combine을 통해 비동기적으로 처리할 수 있습니다.
 또한, 배치 업데이트, 배열 데이터 저장, 페이징 처리 등의 고급 기능도 제공합니다.

 ## 주요 기능:
 - **데이터 생성, 저장, 읽기, 삭제**: Core Data에서의 기본 CRUD 작업을 제공합니다.
 - **배열 데이터 처리**: JSON 인코딩을 통해 배열 데이터를 저장하고 불러옵니다.
 - **배치 업데이트**: 대량의 데이터를 일괄 업데이트합니다.
 - **페이징 처리**: 데이터를 페이징하여 불러올 수 있습니다.
 - **백그라운드 작업 처리**: Core Data의 비동기 백그라운드 작업을 지원합니다.

 ## 사용 예시:
 ```swift
 let coreDataUtility = CoreDataUtility(modelName: "MyModel")

 // 새로운 엔티티 생성
 let newEntity = coreDataUtility.createEntity(MyEntity.self)

 // 데이터 저장
 coreDataUtility.saveContext()
     .sink(receiveCompletion: { completion in
         if case .failure(let error) = completion {
             print("Error saving context: \(error)")
         }
     }, receiveValue: { success in
         print("Context saved successfully: \(success)")
     })

 // 데이터 불러오기
 let fetchRequest: NSFetchRequest<MyEntity> = MyEntity.fetchRequest()
 coreDataUtility.fetchEntities(with: fetchRequest)
     .sink(receiveCompletion: { completion in
         if case .failure(let error) = completion {
             print("Error fetching data: \(error)")
         }
     }, receiveValue: { entities in
         print("Fetched entities: \(entities)")
     })
 
 // 배열 데이터 저장
 let myArray = ["Item1", "Item2", "Item3"]
 coreDataUtility.saveArray(myArray, forKey: "myArrayKey")
     .sink(receiveCompletion: { completion in
         if case .failure(let error) = completion {
             print("Error saving array: \(error)")
         }
     }, receiveValue: { success in
         print("Array saved successfully: \(success)")
     })
 
 // 배열 데이터 불러오기
 coreDataUtility.fetchArray([String].self, forKey: "myArrayKey", from: newEntity)
     .sink(receiveCompletion: { completion in
         if case .failure(let error) = completion {
             print("Error fetching array: \(error)")
         }
     }, receiveValue: { array in
         print("Fetched array: \(array)")
     })
 ```
 
 이 클래스는 Core Data와 관련된 작업을 간단하게 처리할 수 있도록 설계되었습니다. 
 Combine을 통해 비동기적인 데이터를 쉽게 다룰 수 있으며, 다양한 기능을 통해 대량 데이터 처리와 페이징 등을 지원합니다.
 */

import Foundation
import CoreData
import Combine


public class CoreDataUtility {
    
    private let persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext { persistentContainer.viewContext }
    private var cancellables = Set<AnyCancellable>()
    
    /// 초기화 메서드 - Persistent Container 설정
    public init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
    }
    
    /// 데이터를 저장하는 메서드
    /// - Returns: 저장 성공 여부를 비동기적으로 반환하는 `AnyPublisher<Bool, CoreDataError>`
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
    
    /// 엔티티를 생성하는 메서드
    /// - Parameter entity: 생성할 Core Data 엔티티 타입
    /// - Returns: 지정된 타입의 새 엔티티
    public func createEntity<T: NSManagedObject>(_ entity: T.Type) -> T {
        return T(context: context)
    }
    
    /// 데이터를 불러오는 메서드
    /// - Parameter fetchRequest: 데이터를 불러올 NSFetchRequest 객체
    /// - Returns: 엔티티 배열을 비동기적으로 반환하는 `AnyPublisher<[T], CoreDataError>`
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
    
    /// 엔티티를 삭제하는 메서드
    /// - Parameter entity: 삭제할 엔티티
    /// - Returns: 삭제 성공 여부를 비동기적으로 반환하는 `AnyPublisher<Bool, CoreDataError>`
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
    
    /// 모든 엔티티를 삭제하는 메서드
    /// - Parameter entity: 삭제할 엔티티 타입
    /// - Returns: 삭제 성공 여부를 비동기적으로 반환하는 `AnyPublisher<Bool, CoreDataError>`
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
    
    /// 배열 데이터를 CoreData에 저장하는 유틸리티 메서드
    /// - Parameter array: 저장할 배열 데이터
    /// - Parameter key: 배열 데이터를 저장할 엔티티의 속성 키
    /// - Returns: 저장 성공 여부를 비동기적으로 반환하는 `AnyPublisher<Bool, CoreDataError>`
    public func saveArray<T: Encodable>(_ array: [T], forKey key: String) -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            do {
                let data = try JSONEncoder().encode(array)
                let entity = self.createEntity(MyEntity.self)
                entity.setValue(data, forKey: key)
                try self.context.save()
                promise(.success(true))
            } catch {
                promise(.failure(.saveError(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 배열 데이터를 CoreData에서 불러오는 유틸리티 메서드
    /// - Parameter type: 불러올 배열 데이터의 타입
    /// - Parameter key: 배열 데이터를 저장한 엔티티의 속성 키
    /// - Parameter entity: 데이터를 불러올 엔티티
    /// - Returns: 배열 데이터를 비동기적으로 반환하는 `AnyPublisher<[T], CoreDataError>`
    public func fetchArray<T: Decodable>(_ type: T.Type, forKey key: String, from entity: MyEntity) -> AnyPublisher<[T], CoreDataError> {
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
    
    /// 배치 업데이트를 수행하는 메서드
    /// - Parameter entity: 업데이트할 엔티티 타입
    /// - Parameter propertiesToUpdate: 업데이트할 속성 목록
    /// - Returns: 업데이트 성공 여부를 비동기적으로 반환하는 `AnyPublisher<Bool, CoreDataError>`
    public func batchUpdateEntity<T: NSManagedObject>(_ entity: T.Type, propertiesToUpdate: [String: Any]) -> AnyPublisher<Bool, CoreDataError> {
        return Future { promise in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
            let batchUpdateRequest = NSBatchUpdateRequest(fetchRequest: fetchRequest)
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
    
    /// 페이징을 위한 데이터 불러오기 메서드
    /// - Parameter fetchRequest: 데이터를 불러올 NSFetchRequest 객체
    /// - Parameter limit: 불러올 데이터 개수
    /// - Parameter offset: 데이터 시작점
    /// - Returns: 엔티티 배열을 비동기적으로 반환하는 `AnyPublisher<[T], CoreDataError>`
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
    
    /// 백그라운드에서 데이터를 처리하는 메서드
    /// - Parameter block: 백그라운드에서 수행할 작업을 담은 클로저
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
