//
//  DynamoDBController.swift
//  
//
//  Created by Alexey Pichukov on 28.09.2020.
//

import AWSLambdaEvents
import AWSLambdaRuntime
import AsyncHTTPClient
import AWSDynamoDB
import DynamoDBService

public class DynamoDBController<T: DynamoDBConvertable & Codable> {
    
    private let dbService: DBService
    
    public init(httpClient: HTTPClient, tableName: String, region: Region) {
        dbService = DBService(httpClient: httpClient, tableName: tableName, region: region)
    }
    
    public func createItem(context: Lambda.Context, event: APIGateway.Request) -> EventLoopFuture<APIGateway.Response> {
        guard let item: T = try? event.decode() else {
            return context.eventLoop.makeSucceededFuture(APIGateway.Response(with: ErrorType.parsing,
                                                                            statusCode: .badRequest))
        }
        return dbService.create(item: item).map { result -> APIGateway.Response in
            switch result {
                case .success:
                    return APIGateway.Response(with: EmptyObject(), statusCode: .ok)
                case .failure(let error):
                    return APIGateway.Response(with: error, statusCode: .badRequest)
            }
        }
    }
    
    public func readItem(context: Lambda.Context, event: APIGateway.Request) -> EventLoopFuture<APIGateway.Response> {
        guard let id = event.pathParameters?[T.primaryKeyField] else {
            return context.eventLoop.makeSucceededFuture(APIGateway.Response(with: ErrorType.parsing,
                                                                            statusCode: .badRequest))
        }
        return dbService.read(itemWithPrimaryKey: id).map { (result: Result<T, DynamoDBError>) -> APIGateway.Response in
            switch result {
                case .success(let item):
                    return APIGateway.Response(with: item, statusCode: .ok)
                case .failure(let error):
                    return APIGateway.Response(with: error, statusCode: .badRequest)
            }
        }
    }
    
    public func deleteItem(context: Lambda.Context, event: APIGateway.Request) -> EventLoopFuture<APIGateway.Response> {
        guard let id = event.pathParameters?[T.primaryKeyField] else {
            return context.eventLoop.makeSucceededFuture(APIGateway.Response(with: ErrorType.parsing,
                                                                             statusCode: .badRequest))
        }
        return dbService.delete(itemWithPrimaryKey: id,
                                keyFieldName: T.primaryKeyField).map { (result: Result<Void, DynamoDBError>) -> APIGateway.Response in
            switch result {
                case .success:
                    return APIGateway.Response(with: EmptyObject(), statusCode: .ok)
                case .failure(let error):
                    return APIGateway.Response(with: error, statusCode: .badRequest)
            }
        }
    }
    
    public func updateItem(context: Lambda.Context, event: APIGateway.Request) -> EventLoopFuture<APIGateway.Response> {
        guard let item: T = try? event.decode() else {
            return context.eventLoop.makeSucceededFuture(APIGateway.Response(with: ErrorType.parsing,
                                                                                statusCode: .badRequest))
        }
        return dbService.update(item: item).map { result -> APIGateway.Response in
            switch result {
                case .success:
                    return APIGateway.Response(with: EmptyObject(), statusCode: .ok)
                case .failure(let error):
                    return APIGateway.Response(with: error, statusCode: .badRequest)
            }
        }
    }
    
}
