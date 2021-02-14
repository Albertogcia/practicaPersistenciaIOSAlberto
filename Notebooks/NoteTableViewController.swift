import CoreData
import UIKit

class NoteTableViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet var searchBar: UISearchBar?
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    var notebook: NotebookMO?
    
    public convenience init(dataController: DataController) {
        self.init()
        self.dataController = dataController
    }
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar?.delegate = self
        self.title = notebook?.title
        initializeFetchResultsController()
        setupNavigationItem()
    }
    
    func initializeFetchResultsController() {
        guard let dataController = dataController,
              let notebook = notebook
        else {
            return
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        
        let noteCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        fetchRequest.sortDescriptors = [noteCreatedAtSortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "notebook == %@", notebook)
        
        let managedObjectContext = dataController.viewContext
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: managedObjectContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        
        fetchResultsController?.delegate = self
        
        do {
            try fetchResultsController?.performFetch()
        } catch {
            fatalError("couldn't find notes \(error.localizedDescription) ")
        }
    }
    
    func setupNavigationItem() {
        let addNoteBarButtonItem = UIBarButtonItem(title: "Add Note",
                                                   style: .done,
                                                   target: self,
                                                   action: #selector(createAndPresentImagePicker))
        
        navigationItem.rightBarButtonItem = addNoteBarButtonItem
    }
        
    @objc
    func createAndPresentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
           let availabletypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)
        {
            picker.mediaTypes = availabletypes
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL {
                if let notebook = self.notebook {
                    self.dataController?.addNote(with: urlImage, notebook: notebook)
                }
            }
        }
    }
    
    // MARK: - UITableView functions

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCellIdentifier",
                                                 for: indexPath)
        
        guard let note = fetchResultsController?.object(at: indexPath) as? NoteMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        cell.textLabel?.text = note.title
        
        if let noteCreatedAt = note.createdAt {
            cell.detailTextLabel?.text = HelperDateFormatter.textFrom(date: noteCreatedAt)
        }
        
        if let photo = note.photos?.anyObject() as? PhotographMO,
           let imageData = photo.imageData,
           let image = UIImage(data: imageData)
        {
            cell.imageView?.image = image
        }
        else{
            cell.imageView?.image = nil
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteDetailsSegueIdentifier", sender: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier, segueId == "noteDetailsSegueIdentifier" {
            let destination = segue.destination as! NoteDetailsViewController
            let indexPathSelected = tableView.indexPathForSelectedRow!
            let selectedNote = fetchResultsController?.object(at: indexPathSelected) as! NoteMO
            destination.note = selectedNote
            destination.dataController = dataController
        }
    }
}

// MARK: - UISearchBarDelegate

extension NoteTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let notebook = self.notebook else { return }
        
        var searchPredicate: NSPredicate
        if searchText.isEmpty {
            searchPredicate = NSPredicate(format: "notebook == %@", notebook)
        } else {
            searchPredicate = NSPredicate(format: "notebook == %@ AND title CONTAINS[c] %@", notebook, searchText)
        }
        fetchResultsController?.fetchRequest.predicate = searchPredicate
        do {
            try fetchResultsController?.performFetch()
            tableView.reloadData()
        } catch {
            fatalError("couldn't find notes \(error.localizedDescription) ")
        }
    }
}

// MARK: - NSFetchResultsControllerDelegate.

extension NoteTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move, .update:
            break
        @unknown default: fatalError()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError()
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
