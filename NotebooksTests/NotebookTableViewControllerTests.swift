import CoreData
@testable import Notebooks
import XCTest

class NotebookTableViewControllerTests: XCTestCase {
    private let modelName = "NotebooksModel"
    private let optionalStoreName = "NotebooksModelTest"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { _ in }
        dataController.delete()
    }

    func testFetchResultsController_FetchNotebooksInViewContext_InMemory() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        dataController.loadNotebooksIntoViewContext()
        
        let notebookViewController = NotebookTableViewController(dataController: dataController)
        
        notebookViewController.loadViewIfNeeded()
        
        let foundNotebooks = notebookViewController.fetchResultsController?.fetchedObjects?.count
        
        XCTAssertEqual(foundNotebooks, 3)
    }
    
    func testFetchResultsController_FetchNotebooksInViewContext_InPersistentStore() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        dataController.loadNotebooksIntoViewContext()
        dataController.save()
        dataController.reset()
        
        let notebookViewController = NotebookTableViewController(dataController: dataController)
        notebookViewController.loadViewIfNeeded()
        
        let foundNotebooks = notebookViewController.fetchResultsController?.fetchedObjects?.count
        
        XCTAssertEqual(foundNotebooks, 3)
    }
}
