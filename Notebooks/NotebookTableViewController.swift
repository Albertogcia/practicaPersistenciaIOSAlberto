import CoreData
import UIKit

class NotebookTableViewController: UITableViewController {
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
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
        
        initializeFetchResultsController()
        
        self.title = "Notebooks"

        let loadDataBarbuttonItem = UIBarButtonItem(title: "Load",
                                                    style: .done,
                                                    target: self,
                                                    action: #selector(loadData))
            
        let deleteBarButtonItem = UIBarButtonItem(title: "Delete",
                                                  style: .done,
                                                  target: self,
                                                  action: #selector(deleteData))
        
        navigationItem.leftBarButtonItems = [deleteBarButtonItem, loadDataBarbuttonItem]
        navigationItem.rightBarButtonItems = []
    }
    
    func initializeFetchResultsController() {
        guard let dataController = dataController else { return }
        let viewContext = dataController.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Notebook")
        let notebookTitleSortDescriptor = NSSortDescriptor(key: "title",
                                                           ascending: true)
        request.sortDescriptors = [notebookTitleSortDescriptor]
                
        fetchResultsController = NSFetchedResultsController(fetchRequest: request,
                                                            managedObjectContext: viewContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        fetchResultsController?.delegate = self
        
        do {
            try fetchResultsController?.performFetch()
        } catch {
            print("Error while trying to perform a notebook fetch.")
        }
    }
    
    @objc
    func deleteData() {
        dataController?.save()
        dataController?.delete()
        dataController?.reset()
        initializeFetchResultsController()
        tableView.reloadData()
    }
    
    @objc
    func loadData() {
        dataController?.loadNotesInBackground()
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "notebookCell",
                                                 for: indexPath)
        
        guard let notebook = fetchResultsController?.object(at: indexPath) as? NotebookMO else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        cell.textLabel?.text = notebook.title
        
        if let createdAt = notebook.createdAt {
            cell.detailTextLabel?.text = HelperDateFormatter.textFrom(date: createdAt)
        }
        
        if let photograph = notebook.photograph,
           let imageData = photograph.imageData,
           let image = UIImage(data: imageData)
        {
            cell.imageView?.image = image
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "noteSegueIdentifier", sender: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let segueId = segue.identifier, segueId == "noteSegueIdentifier" {
            let destination = segue.destination as! NoteTableViewController
            let indexPathSelected = tableView.indexPathForSelectedRow!
            let selectedNotebook = fetchResultsController?.object(at: indexPathSelected) as! NotebookMO
            destination.notebook = selectedNotebook
            destination.dataController = dataController
        }
    }
}

// MARK: - NSFetchResultsControllerDelegate.

extension NotebookTableViewController: NSFetchedResultsControllerDelegate {
    
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
