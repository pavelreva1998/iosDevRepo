//
//  PRPhotoPicker.swift
//  Samples
//
//  Created by developer on 8/25/18.
//  Copyright © 2018 revainc. All rights reserved.
//


import UIKit
import AVFoundation

@objc protocol RPImagePickerDelegate: class
{
    // Implement this callback for picked photo
    @objc optional func photoDidPicked(_ image: UIImage)
    // Implement this callback for picked videourl
    @objc optional func videoDidPicked(_ videoUrl: NSURL)
    // Implment this callback for show to user, that he should allow access in settings
    func pickerDidRejected()
}

// The enum describes media types which you can get via the picker
public enum PRMediaType: String
{
    case photo = "public.image"
    case video = "public.movie"
}

// !!!! IF YOU WANT TO USE THIS CLASS YOU SHOULD ADD       Privacy – Photo Library Usage…  and    Privacy - Camera Usage Description      TO YOUR info.plist
// !!!! Use the variable of the class only like class variable
class PRPhotoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    // presenting viewConroller
    private weak var vc: UIViewController?
    
    // additional settings parameters for the class
    var useCrop: Bool = false
    var mediaType: PRMediaType = .photo
    
    // use this variables to use picker without alert
    //only one of them can be true, if you want to see alert both variables should be false (do anything)
    var useCameraOnly: Bool = false
    {
        didSet
        {
            if useCameraOnly
            {
                useLibraryOnly = false
            }
        }
    }
    
    var useLibraryOnly: Bool = false
    {
        didSet
        {
            if useLibraryOnly
            {
                useCameraOnly = false
            }
        }
    }
    
    // One of these parameters shoud be mandatory for showind alert
    var alertTitle: String?
    var alertMessage: String?
    
    // User this variables to customize your alert
    var cameraTitle: String? = "Take a Photo"
    var chooseFromLibraryTitle: String? = "Choose from library"
    var cancelButtonTitle: String? = "Cancel"
    
    // Strategy for showing alert
    var alertStyle: UIAlertControllerStyle = .actionSheet

    // ViewController, that use the picker should implement this delegate for getting result and handling of access error
    weak var delegate: RPImagePickerDelegate?
    
    // init the picker with viewController and(or) customize the behaviour
    init(vc aVc: UIViewController, alertMessage aAlertMessage: String?, useCrop aUseCrop: Bool = false, mediaType aMediaType: PRMediaType = .photo)
    {
        vc = aVc
        useCrop = aUseCrop
        mediaType = aMediaType
        
        super.init()
    }
    
    // use the method for picking meadia content
    func pick()
    {
        assert(!(useCameraOnly && useLibraryOnly), "Only one of the params can be true")
        
        if !useCameraOnly && !useLibraryOnly
        {
            assert(alertTitle != nil || alertMessage != nil, "Title or message shouldn't be nil for showing alert")
            
            let actionSheet = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: alertStyle)
            
            actionSheet.addAction(UIAlertAction(title: cameraTitle, style: .default) { _ in
                self.takePhoto(aSourceType: .camera)
            })
            
            actionSheet.addAction(UIAlertAction(title: chooseFromLibraryTitle, style: .default) { _ in
                self.takePhoto(aSourceType: .photoLibrary)
            })
            
            actionSheet.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            })
            
            vc?.present(actionSheet, animated: true, completion: nil)
        } else if useCameraOnly
        {
            takePhoto(aSourceType: .camera)
        } else if useLibraryOnly
        {
            takePhoto(aSourceType: .photoLibrary)
        }
    }
    
    // The method check for access and erquest it if need
    private func takePhoto(aSourceType: UIImagePickerControllerSourceType)
    {
        if !UIImagePickerController.isSourceTypeAvailable(aSourceType)
        {
            delegate?.pickerDidRejected()
            return
        }
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.delegate = self
        imagePickerController.sourceType = aSourceType
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = [mediaType.rawValue]
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus
        {
        case .authorized:
            vc?.present(imagePickerController, animated: true, completion: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    
                    if granted
                    {
                        strongSelf.vc?.present(imagePickerController, animated: true, completion: nil)
                    } else
                    {
                        self?.delegate?.pickerDidRejected()
                    }
                }
            })
        default:
            delegate?.pickerDidRejected()
        }
    }
    
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any])
    {
        if mediaType == .photo
        {
            let image = info[UIImagePickerControllerEditedImage] as? UIImage
            
            if let image = image
            {
                delegate?.photoDidPicked?(image)
            }
        } else
        {
            let videoURL: NSURL? = info["UIImagePickerControllerReferenceURL"] as? NSURL
            
            if let videoURL = videoURL
            {
                delegate?.videoDidPicked?(videoURL)
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        picker.dismiss(animated: true, completion: nil)
    }
}
