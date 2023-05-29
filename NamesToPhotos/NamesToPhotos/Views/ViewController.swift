import UIKit
import CoreData
import LocalAuthentication

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var people: [Person] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - Authentification
        let ac = UIAlertController(title: "Authentification", message: "To acces this app you need to verify yourself by going through authentification", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [self] _ in
            let LAcontext = LAContext()
            var error: NSError?
            
            if LAcontext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Identify yourself!"
                
                LAcontext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { succes, authentificationError in
                    DispatchQueue.main.async { [self] in
                        if succes {
                            let ac = UIAlertController(title: "Succes", message: "Your face was succesfuly verified", preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                                self?.collectionView.isHidden = false
                            })
                            self.present(ac, animated: true)
                            return
                        } else {
                            present(ac, animated: true)
                        }
                    }
                }
            } else {
                let ac = UIAlertController(title: "Biometry unavalible", message: "Your device is not configured for biometric authentification", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                collectionView.isHidden = false
            }
            return
        })
        present(ac, animated: true)
        
        // MARK: - NavbarItems
        let add = UIBarButtonItem(image: UIImage(systemName: "plus.app.fill"), style: .plain, target: self, action: #selector(addPerson))
        add.tintColor = .systemYellow
        let info = UIBarButtonItem(image: UIImage(systemName: "info.circle.fill"), style: .plain, target: self, action: #selector(showInfo))
        info.tintColor = .systemYellow
        navigationItem.rightBarButtonItem = add
        navigationItem.leftBarButtonItem = info
        
        // MARK: - Default Settings
        title = "NamesToPhotos"
        overrideUserInterfaceStyle = .dark
        
        // MARK: - Fetch existing people
        fetchPeople()
    }
    
    func fetchPeople(){
        do {
            self.people = try context.fetch(Person.fetchRequest())
            self.collectionView.reloadData()
        }
        catch {
            fatalError("\(error)")
        }
    }
    
    @objc func addPerson() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func showInfo() {
        let ac = UIAlertController(title: "Information", message: "This app is showing all events you have ever added to it.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            fatalError("UNABLE TO DEQUEUE REUSABLE CELL")
        }
        
        let person = people[indexPath.item]
        
        cell.titleLabel.text = person.titleName
        cell.subtitlelabel.text = person.subtitleLabel
        
        let path = getDocumentsDirectory().appendingPathComponent(person.image!)
        cell.ImageView.image = UIImage(contentsOfFile: path.path)
        cell.ImageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.ImageView.layer.borderWidth = 2.0
        cell.ImageView.layer.cornerRadius = 3.0
        cell.layer.cornerRadius = 7.0
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 160, height: 210)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        let person = Person( context: context)
        person.image = imageName
        person.titleName = "Set Title"
        person.subtitleLabel = "Set Description"
        people.append(person)
        collectionView.reloadData()
        
        do {
            try self.context.save()
        }
        catch {
            fatalError("\(error)")
        }
        self.fetchPeople()
        dismiss(animated: true)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        let chooseAC = UIAlertController(title: "Choose action: ", message: nil, preferredStyle: .actionSheet)
        chooseAC.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
            let ac = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
            ac.addTextField{ textField in
                textField.placeholder = "Enter Title"
            }
            ac.addTextField{ textField in
                textField.placeholder = "Enter Subtitle"
            }
            ac.addAction(UIAlertAction(title: "Cancel", style: .destructive))
            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
                guard let newName = ac?.textFields?[0].text else { return }
                guard let newDesc = ac?.textFields?[1].text else { return }
                person.titleName = newName
                person.subtitleLabel = newDesc
                self?.collectionView.reloadData()
                do {
                    try self?.context.save()
                }
                catch{
                    fatalError("\(error)")
                }
                self?.fetchPeople()
            })
            self.present(ac, animated: true)
        })
        chooseAC.addAction(UIAlertAction(title: "Delete", style: .default) {  _ in
            let personToDelete = self.people[indexPath.item]
            self.context.delete(personToDelete)
            self.people.remove(at: indexPath.item)
            do {
                try self.context.save()
            }
            catch{
                fatalError("\(error)")
            }
            self.fetchPeople()
        })
        
        chooseAC.addAction(UIAlertAction(title: "Cancel", style: .destructive))
        present(chooseAC, animated: true)
    }
}
