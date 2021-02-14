import CoreData
@testable import Notebooks
import XCTest

class NotebooksTests: XCTestCase {
    private let modelName = "NotebooksModel"
    private let optionalStoreName = "NotebooksTest"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { _ in }
        dataController.delete()
    }

    func testInit_DataController_Initializes() {
        DataController(modelName: modelName, optionalStoreName: optionalStoreName) { _ in
            XCTAssert(true)
        }
    }
    
    func testInit_Notebook() {
        DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard let persistentContainer = persistentContainer else {
                XCTFail()
                return
            }
            let managedObjectContext = persistentContainer.viewContext
            
            let notebook1 = NotebookMO.createNotebook(createdAt: Date(),
                                                      title: "notebook 1",
                                                      in: managedObjectContext)
            
            XCTAssertNotNil(notebook1)
        }
    }
    
    func testFetch_DataController_FetchesANotebook() {
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        
        dataController.loadNotebooksIntoViewContext()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 3)
    }
    
    func testFilter_DataController_FilterNotebooks() {
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        
        dataController.loadNotebooksIntoViewContext()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        
        fetchRequest.predicate = NSPredicate(format: "title == %@", "notebook1")
        
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 1)
    }
    
    func testSave_DataController_SavesInPersistentStore() {
        
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }
        
        dataController.loadNotebooksIntoViewContext()
        dataController.save()
        dataController.reset()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 3)
    }
    
    func testDelete_DataController_DeletesDataInPersistentStore() {
        let dataController = DataController(modelName: modelName, optionalStoreName: optionalStoreName) { (persistentContainer) in
            guard persistentContainer != nil else {
                XCTFail()
                return
            }
        }

        dataController.loadNotebooksIntoViewContext()
        dataController.save()
        dataController.reset()
        dataController.delete()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebooks = dataController.fetchNotebooks(using: fetchRequest)
        
        XCTAssertEqual(notebooks?.count, 0)
    }
}
