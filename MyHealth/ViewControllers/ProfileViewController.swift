//
//  ProfileViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 12/8/23.
//

import UIKit
import HealthKit

class ProfileViewController: UIViewController, UITextFieldDelegate {
    // MARK: Connection
    @IBOutlet weak var firstNameTxt: UITextField!
    @IBOutlet weak var lastNameTxt: UITextField!
    @IBOutlet weak var birthDateTxt: UITextField!
    @IBOutlet weak var bioSexTxt: UITextField!
    @IBOutlet weak var bloodTypeTxt: UITextField!
    @IBOutlet weak var skinTypeTxt: UITextField!
    @IBOutlet weak var fullNameTxt: UILabel!
    @IBOutlet weak var optionView: UIView!
    @IBOutlet weak var dpkDate: UIDatePicker!
    @IBOutlet weak var dpkOption: UIPickerView!
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var profileView: UIView!
    
    // MARK: Variables
    let healthStore = HealthData.healthStore
    var userData = ViewModels.userData
    var selectedTxtField: UITextField?
    let bioSexOptions = ["", "Female", "Male", "Other"]
    let bloodTypeOptions = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    let skinTypeOptions = ["", "Type I", "Type II", "Type III", "Type IV", "Type V", "Type VI"]
    var selectedOptions: [String] = []
    var imgTapGesture: UIGestureRecognizer!
    var ispfpChanged = false
    
    // MARK: View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = editButton()
        firstNameTxt.delegate = self
        lastNameTxt.delegate = self
        birthDateTxt.delegate = self
        bioSexTxt.delegate = self
        bloodTypeTxt.delegate = self
        skinTypeTxt.delegate = self
        dpkOption.delegate = self
        dpkOption.dataSource = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        
        let path = ViewModels.userData.imgPath
        ViewModels.getImageFromPath(path: path, completion: { image in
            DispatchQueue.main.async {
                self.profileImgView.image = image
            }
        })
        profileView.layer.cornerRadius = profileView.frame.size.width / 2
        
        reloadData()
    }
    
    // MARK: Functions
    func getHealthDetailData() {
        if let birthDay = try? healthStore.dateOfBirthComponents() {
            userData.birthDate = Calendar.current.date(from: birthDay)
        } else {
            userData.birthDate = nil
        }
        
        if let bioSex = try? healthStore.biologicalSex() {
            userData.bioSex = UserData.getSex(rawValue: bioSex.biologicalSex.rawValue)
        } else {
            userData.bioSex = nil
        }
        
        if let bloodType = try? healthStore.bloodType() {
            userData.bloodType = UserData.getBloodType(rawValue: bloodType.bloodType.rawValue)
        } else {
            userData.bloodType = nil
        }
        
        if let skinType = try? healthStore.fitzpatrickSkinType() {
            userData.fitzpatrickSkinType = UserData.getSkinType(rawValue: skinType.skinType.rawValue)
        } else {
            userData.fitzpatrickSkinType = nil
        }
        
        ViewModels.saveUserData(userData)
    }
    
    func reloadData() {
        DispatchQueue.main.async {
            self.bioSexTxt.text = self.userData.bioSex?.rawValue
            self.bloodTypeTxt.text = self.userData.bloodType?.rawValue
            self.skinTypeTxt.text = self.userData.fitzpatrickSkinType?.rawValue
            
            if let birthDate = self.userData.birthDate {
                self.birthDateTxt.text = "\(birthDate.standardString) (\(birthDate.age))"
            } else {
                self.birthDateTxt.text = nil
            }
            let firstName = self.userData.firstName ?? ""
            let lastName = self.userData.lastName ?? ""
            self.firstNameTxt.text = firstName
            self.lastNameTxt.text = lastName
            self.fullNameTxt.text = "\(firstName) \(lastName)"
            
        }
    }
    func editButton() -> UIBarButtonItem {
        let save = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editTapped))
        
        return save
    }
    
    func doneButton() -> UIBarButtonItem {
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        return done
    }
    
    func createClearButton() -> UIButton {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        clearButton.tintColor = .red
        clearButton.addTarget(self, action: #selector(clearBthDayTapped), for: .touchUpInside)
        let size = birthDateTxt.frame.size
        clearButton.frame = CGRect(x: 0, y: 0, width: size.width, height: size.width)
        return clearButton
    }
    
    func enableTextField(_ txt: UITextField, placeholder: String = "Not Set") {
        txt.isEnabled = true
        txt.textColor = .systemBlue
        txt.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.systemBlue]
        )
    }
    
    func disableTextField(_ txt: UITextField, placeholder: String = "Not Set") {
        txt.textColor = .label
        txt.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.placeholderText]
        )
        txt.isEnabled = false
    }
    
    func hideAllPicker() {
        optionView.subviews.forEach({
            $0.isHidden = true
        })
        removeClearButton()
    }
    
    func addClearButton() {
        birthDateTxt.rightView = createClearButton()
        birthDateTxt.rightViewMode = .always
    }
    
    func removeClearButton() {
        birthDateTxt.rightView = nil
        birthDateTxt.rightViewMode = .never
    }
    
    func selectBioSex() {
        hideAllPicker()
        dpkOption.isHidden = false
        selectedOptions = bioSexOptions
        dpkOption.reloadAllComponents()
        if let bioSex = bioSexTxt.text {
            let i = selectedOptions.firstIndex(where: {$0 == bioSex}) ?? 0
            dpkOption.selectRow(i, inComponent: 0, animated: false)
        }
        optionView.isHidden = false
        selectedTxtField = bioSexTxt
    }
    
    func selectBloodType() {
        hideAllPicker()
        dpkOption.isHidden = false
        selectedOptions = bloodTypeOptions
        dpkOption.reloadAllComponents()
        if let bloodType = bloodTypeTxt.text {
            let i = selectedOptions.firstIndex(where: {$0 == bloodType}) ?? 0
            dpkOption.selectRow(i, inComponent: 0, animated: false)
        }
        optionView.isHidden = false
        selectedTxtField = bloodTypeTxt
    }
    
    func selectSkinType() {
        hideAllPicker()
        dpkOption.isHidden = false
        optionView.isHidden = false
        selectedOptions = skinTypeOptions
        dpkOption.reloadAllComponents()
        if let skinType = skinTypeTxt.text {
            let i = selectedOptions.firstIndex(where: {$0 == skinType}) ?? 0
            dpkOption.selectRow(i, inComponent: 0, animated: false)
        }
        optionView.isHidden = false
        selectedTxtField = skinTypeTxt
    }
    
    //MARK: Objective C Function
    @objc func editTapped() {
        enableTextField(firstNameTxt, placeholder: "First Name")
        enableTextField(lastNameTxt, placeholder: "Last Name")
        enableTextField(birthDateTxt)
        enableTextField(bioSexTxt)
        enableTextField(bloodTypeTxt)
        enableTextField(skinTypeTxt)
        self.navigationItem.rightBarButtonItem = doneButton()
        
        imgTapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImgView.addGestureRecognizer(imgTapGesture)
    }
    
    @objc func doneTapped() {
        disableTextField(firstNameTxt, placeholder: "First Name")
        disableTextField(lastNameTxt, placeholder: "Last Name")
        disableTextField(birthDateTxt)
        disableTextField(bioSexTxt)
        disableTextField(bloodTypeTxt)
        disableTextField(skinTypeTxt)
        
        hideAllPicker()
        optionView.isHidden = true
        selectedTxtField = nil
        
        let firstName = firstNameTxt.text
        let lastName = lastNameTxt.text
        userData.firstName = firstName
        userData.lastName = lastName
        fullNameTxt.text = "\(firstName ?? "") \(lastName ?? "")"
        
        ViewModels.saveUserData(userData)
        
        if ispfpChanged,
           let image = profileImgView.image {
            ViewModels.saveProfileImage(image)
            ispfpChanged = false
        }
        self.navigationItem.rightBarButtonItem = editButton()
        
        profileImgView.removeGestureRecognizer(imgTapGesture)
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
        hideAllPicker()
        optionView.isHidden = true
    }
    
    @objc func clearBthDayTapped() {
        birthDateTxt.text = nil
        userData.birthDate = nil
        hideAllPicker()
        optionView.isHidden = true
    }
    
    @objc func imageTapped() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    // MARK: Text Field Delegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let shouldEdit: Bool
        switch textField {
        case birthDateTxt:
            hideAllPicker()
            if let bthDate = userData.birthDate {
                dpkDate.date = bthDate
            }
            dpkDate.isHidden = false
            optionView.isHidden = false
            if let _ = userData.birthDate {
                addClearButton()
            }
            shouldEdit = false
        case bioSexTxt:
            selectBioSex()
            shouldEdit = false
        case bloodTypeTxt:
            selectBloodType()
            shouldEdit = false
        case skinTypeTxt:
            selectSkinType()
            shouldEdit = false
        default:
            hideAllPicker()
            optionView.isHidden = true
            selectedTxtField = nil
            shouldEdit = true
        }
        
        if !shouldEdit {
            view.endEditing(true)
        }
        
        return shouldEdit
    }
    
    // MARK: Action Event Handlers
    @IBAction func getDataFromHealthKit(_ sender: Any) {
        if HKHealthStore.isHealthDataAvailable() {
            let read = Set([
                HKCharacteristicType(.biologicalSex),
                HKCharacteristicType(.dateOfBirth),
                HKCharacteristicType(.bloodType),
                HKCharacteristicType(.fitzpatrickSkinType)
            ])
            HealthData.requestHealthDataAccessIfNeeded(toShare: nil, read: read) {success in 
                if success {
                    self.getHealthDetailData()
                    self.reloadData()
                }
            }
        }
    }
    
    @IBAction func changeDate(_ sender: Any) {
        let birthDate = dpkDate.date
        birthDateTxt.text = "\(birthDate.standardString) (\(birthDate.age))"
        userData.birthDate = birthDate
        if let _ = birthDateTxt.rightView {} else {
            addClearButton()
        }
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ProfileViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectedOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return selectedOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRow = selectedOptions[row]
        selectedTxtField?.text = selectedRow
        switch selectedTxtField {
        case bioSexTxt:
            userData.bioSex = UserData.sex(rawValue: selectedRow)
        case bloodTypeTxt:
            userData.bloodType = UserData.blood(rawValue: selectedRow)
        case skinTypeTxt:
            userData.fitzpatrickSkinType = UserData.skin(rawValue: selectedRow)
        default:
            return
        }
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            profileImgView.image = image
            ispfpChanged = true
        }
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
