import CoreData
import UIKit

class NoteDetailsViewController: UIViewController {
    
    @IBOutlet var noteTitleTextField: UITextField!
    @IBOutlet var noteContentTextView: UITextView!
    @IBOutlet var notePhotosCollectionView: UICollectionView!
    
    var dataController: DataController?
    var fetchResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    let queue = OperationQueue()
    
    var note: NoteMO?
    
    public convenience init(dataController: DataController, note: NoteMO) {
        self.init()
        self.dataController = dataController
        self.note = note
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notePhotosCollectionView.dataSource = self
        notePhotosCollectionView.delegate = self
        setUpLayout()
        initializeFetchResultsController()
        setupNavigationItem()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let title = noteTitleTextField.text {
            note?.title = title
        }
        note?.contents = noteContentTextView.text
        dataController?.save()
    }
    
    func setUpLayout() {
        guard let note = note else { return }
        
        noteTitleTextField.text = note.title
        noteContentTextView.text = note.contents
    }
    
    func initializeFetchResultsController() {
        guard let dataController = dataController,
              let note = note
        else {
            return
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photograph")
        
        let photoCreatedAtSortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [photoCreatedAtSortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "note == %@", note)
        
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
        let addNoteBarButtonItem = UIBarButtonItem(title: "Add Image",
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
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension NoteDetailsViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    {
        picker.dismiss(animated: true) { [unowned self] in
            if let urlImage = info[.imageURL] as? URL, let note = self.note {
                dataController?.addPhotoToNote(with: urlImage, note: note)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension NoteDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchResultsController = fetchResultsController {
            return fetchResultsController.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchResultsController?.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "noteImageIdentifier",
            for: indexPath
        ) as! NotePhotoCell
        
        if let photograph = fetchResultsController?.object(at: indexPath) as? PhotographMO, let imageData = photograph.imageData, let image = UIImage(data: imageData) {
            cell.notePhotoImageView.image = image
        }
        
        cell.backgroundColor = UIColor.black
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NoteDetailsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (view.frame.width - 80) / 3
        return CGSize(width: size, height: size)
    }
      
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(20)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension NoteDetailsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let blockOperation = BlockOperation { [weak self] in
            DispatchQueue.main.async {
                switch type {
                case .insert:
                    self?.notePhotosCollectionView.insertSections(IndexSet(integer: sectionIndex))
                case .delete:
                    self?.notePhotosCollectionView.deleteSections(IndexSet(integer: sectionIndex))
                case .update:
                    self?.notePhotosCollectionView.reloadSections(IndexSet(integer: sectionIndex))
                case .move:
                    break
                @unknown default: fatalError()
                }
            }
        }
        queue.addOperation(blockOperation)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let blockOperation = BlockOperation { [weak self] in
            DispatchQueue.main.async {
                switch type {
                case .insert:
                    self?.notePhotosCollectionView.insertItems(at: [newIndexPath!])
                case .delete:
                    self?.notePhotosCollectionView.deleteItems(at: [indexPath!])
                case .update:
                    self?.notePhotosCollectionView.reloadItems(at: [indexPath!])
                case .move:
                    self?.notePhotosCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
                @unknown default:
                    fatalError()
                }
            }
        }
        queue.addOperation(blockOperation)
    }
    
}
