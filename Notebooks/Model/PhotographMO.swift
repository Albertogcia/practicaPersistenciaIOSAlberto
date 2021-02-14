import Foundation
import CoreData

@objc(PhotographMO)
public class PhotographMO: NSManagedObject {

    static func createPhoto(imageData: Data,
                            managedObjectContext: NSManagedObjectContext, createdAt: Date) -> PhotographMO? {
        let photograph = NSEntityDescription.insertNewObject(forEntityName: "Photograph",
                                                             into: managedObjectContext) as? PhotographMO
        
        photograph?.imageData = imageData
        photograph?.createdAt = createdAt
        
        return photograph
    }
    
    
}
