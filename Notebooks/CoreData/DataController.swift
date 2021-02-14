import Foundation
import CoreData
import UIKit

class DataController: NSObject {
    private let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
        
    @discardableResult
    init(modelName: String, optionalStoreName: String?, completionHandler: (@escaping (NSPersistentContainer?) -> ())) {
        if let optionalStoreName = optionalStoreName {
            let managedObjectModel = Self.manageObjectModel(with: modelName)
            self.persistentContainer = NSPersistentContainer(name: optionalStoreName,
                                                             managedObjectModel: managedObjectModel)
            super.init()
            
            persistentContainer.loadPersistentStores { [weak self] (description, error) in
                if let error = error {
                    fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                }
                
                completionHandler(self?.persistentContainer)
            }
            
        } else {
            
            self.persistentContainer = NSPersistentContainer(name: modelName)
            
            super.init()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.persistentContainer.loadPersistentStores { [weak self] (description, error) in
                    if let error = error {
                        fatalError("Couldn't load CoreData Stack \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        completionHandler(self?.persistentContainer)
                    }
                }
            }
        }
    }
    
    func fetchNotebooks(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [NotebookMO]? {
        do {
            return try persistentContainer.viewContext.fetch(fetchRequest) as? [NotebookMO]
        } catch {
            fatalError("Failure to fetch notebooks with context: \(fetchRequest), \(error)")
        }
    }
    
    func fetchNotes(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [NoteMO]? {
        do {
            return try viewContext.fetch(fetchRequest) as? [NoteMO]
        } catch {
            fatalError("Failure to fetch Notes")
        }
    }
    
    func fetchPhotos(using fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> [PhotographMO]? {
        do {
            return try viewContext.fetch(fetchRequest) as? [PhotographMO]
        }
        catch {
            fatalError("Failure to fetch Photos")
        }
    }
    
    func save() {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("=== could not save view context ===")
            print("error: \(error.localizedDescription)")
        }
    }
    
    func reset() {
        persistentContainer.viewContext.reset()
    }
    
    func delete() {
        guard let persistentStoreUrl = persistentContainer
                .persistentStoreCoordinator.persistentStores.first?.url else {
            return
        }
        
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: persistentStoreUrl,
                                                                                      ofType: NSSQLiteStoreType,
                                                                                      options: nil)
        } catch {
            fatalError("could not delete test database. \(error.localizedDescription)")
        }
    }
    
    static func manageObjectModel(with name: String) -> NSManagedObjectModel {
        guard let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") else {
            fatalError("Error could not find model.")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing managedObjectModel from: \(modelURL).")
        }
        
        return managedObjectModel
    }
    
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let privateMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        privateMOC.parent = viewContext

        privateMOC.perform {
            block(privateMOC)
        }
    }
}

extension DataController {
    
    func loadNotesInBackground() {
        performInBackground { (privateManagedObjectContext) in
            let managedObjectContext = privateManagedObjectContext
            guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                           title: "notebook con notas",
                                                           in: managedObjectContext) else {
                return
            }
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "Nota 1",
                              createdAt: Date(),
                              contents: "Esta es la nota 1")
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "Nota 2",
                              createdAt: Date(),
                              contents: "Esta es la nota 2")
            
            NoteMO.createNote(managedObjectContext: managedObjectContext,
                              notebook: notebook,
                              title: "Nota 3",
                              createdAt: Date(),
                              contents: "Esta es la nota 3")
            
            let notebookImage = UIImage(named: "notebookImage")
            
            if let dataNotebookImage = notebookImage?.pngData() {
                let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                          managedObjectContext: managedObjectContext, createdAt: Date())
            
                notebook.photograph = photograph
            }
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("failure to save in background.")
            }
        }
    }
    
    func loadNotesIntoViewContext() {
        let managedObjectContext = viewContext

        guard let notebook = NotebookMO.createNotebook(createdAt: Date(),
                                                       title: "notebook con notas",
                                                       in: managedObjectContext) else {
            return
        }
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 1",
                          createdAt: Date())
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 2",
                          createdAt: Date())
        
        NoteMO.createNote(managedObjectContext: managedObjectContext,
                          notebook: notebook,
                          title: "nota 3",
                          createdAt: Date())
        
        let notebookImage = UIImage(named: "notebookImage")
        
        if let dataNotebookImage = notebookImage?.pngData() {
            let photograph = PhotographMO.createPhoto(imageData: dataNotebookImage,
                                                      managedObjectContext: managedObjectContext, createdAt: Date())
        
            notebook.photograph = photograph
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("failure to save in background.")
        }
    }
    
    func loadNotebooksIntoViewContext() {
        let managedObjectContext = viewContext
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook1",
                                  in: managedObjectContext)
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook2",
                                  in: managedObjectContext)
        
        NotebookMO.createNotebook(createdAt: Date(),
                                  title: "notebook3",
                                  in: managedObjectContext)
    }
    
    func addNote(with urlImage: URL, notebook: NotebookMO) {
        performInBackground { (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }
            
            let notebookID = notebook.objectID
            let copyNotebook = managedObjectContext.object(with: notebookID) as! NotebookMO
            
            let photograhMO = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext, createdAt: Date())
            
            let note = NoteMO.createNote(managedObjectContext: managedObjectContext,
                                         notebook: copyNotebook,
                                         title: "Nueva nota",
                                         createdAt: Date(),
                                         contents: "Descripción de la nota")
            
            photograhMO?.note = note
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }
    
    func addPhotoToNote(with urlImage: URL, note: NoteMO){
        performInBackground{ (managedObjectContext) in
            guard let imageThumbnail = DownSampler.downsample(imageAt: urlImage),
                  let imageThumbnailData = imageThumbnail.pngData() else {
                return
            }
            
            let noteID = note.objectID
            let copyNote = managedObjectContext.object(with: noteID) as! NoteMO
            
            let photograhMO = PhotographMO.createPhoto(imageData: imageThumbnailData,
                                                       managedObjectContext: managedObjectContext, createdAt: Date())
            
            photograhMO?.note = copyNote
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("could not create note with thumbnail image in background.")
            }
        }
    }
}
