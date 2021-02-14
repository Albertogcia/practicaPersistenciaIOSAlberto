import CoreData
@testable import Notebooks
import XCTest

class NotesTests: XCTestCase {

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
    
    func testCreateAndSearchNote() {
        let expectation = XCTestExpectation(description: "datacontrollerInBackground")
       
        DispatchQueue.global(qos: .userInitiated).async {

            DispatchQueue.main.async {
                let dataController = DataController(modelName: self.modelName,
                                                    optionalStoreName: self.optionalStoreName) { (_) in }
                
                dataController.loadNotesIntoViewContext()
                dataController.save()
                dataController.reset()
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
                
                let notes = dataController.fetchNotes(using: fetchRequest)
                
                XCTAssertEqual(notes?.count, 3)
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testAddAndSearchNotePhoto() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        let managedObjectContext = dataController.viewContext
        
        let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                 title: "notebook1",
                                                 in: dataController.viewContext)
        
        let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                     notebook: notebook!,
                                     title: "note1",
                                     createdAt: Date())
        
        
        let notebookImage = UIImage(named: "notebookImage")
        if let dataNotebookImage = notebookImage?.pngData() {
            let photo = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                      managedObjectContext: managedObjectContext, createdAt: Date())
            photo?.note = note
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        fetchRequest.predicate = NSPredicate(format: "note == %@", note!)
    
        let photos = dataController.fetchPhotos(using: fetchRequest)
        XCTAssertEqual(photos?.count, 1)
    }
    
    func testNoteViewController() {
        let dataController = DataController(modelName: modelName,
                                            optionalStoreName: optionalStoreName) { (_) in }
        
        let managedObjectContext = dataController.viewContext
        
        let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                 title: "notebook1",
                                                 in: dataController.viewContext)
        
        let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                     notebook: notebook!,
                                     title: "note1",
                                     createdAt: Date())
        
        let noteViewController = NoteTableViewController(dataController: dataController)
        noteViewController.notebook = notebook
        
        noteViewController.loadViewIfNeeded()
        
        let notes = noteViewController.fetchResultsController?.fetchedObjects as? [NoteMO]
        
        guard let noteFirstFound = notes?.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(notes?.count, 1)
        XCTAssertEqual(note, noteFirstFound)
    }
}
