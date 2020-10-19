import XCTest

import db_update_lambdaTests

var tests = [XCTestCaseEntry]()
tests += DynamoDBControllerTests.allTests()
XCTMain(tests)
