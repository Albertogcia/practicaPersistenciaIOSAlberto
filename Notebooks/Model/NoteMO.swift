import Foundation
import CoreData

@objc(NoteMO)
public class NoteMO: NSManagedObject {

    @discardableResult
    static func createNote(managedObjectContext: NSManagedObjectContext,
                           notebook: NotebookMO,
                           title: String,
                           createdAt: Date,
                           contents: String? = nil) -> NoteMO? {
        let note = NSEntityDescription.insertNewObject(forEntityName: "Note",
                                                       into: managedObjectContext) as? NoteMO
    
        note?.title = title
        note?.createdAt = createdAt
        note?.notebook = notebook
        note?.contents = contents
        
        return note
    }
}
