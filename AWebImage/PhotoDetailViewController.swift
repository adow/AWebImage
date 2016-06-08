//
//  PhotoDetailViewController.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/2.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView : UIImageView!
    var imageId : Int!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        let url = NSURL(string: "https://drscdn.500px.org/photo/156556773/q%3D80_m%3D1000/93815cf3d792ce50d26b00fe53018061")!
//        self.imageView.aw_downloadImageURL_loading(self.imageUrl, showLoading: true) { (_, _) in
//            
//        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPhoto(self.imageId)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PhotoDetailViewController {
    struct Photo {
        var id : Int!
        var name : String!
        var description : String!
        var image_url : String!
        init (dict:[String:AnyObject]) {
            self.id = Int.valueFromAnyObject(dict["id"])
            self.name = String.stringFromAnyObject(dict["name"])
            self.description = String.stringFromAnyObject(dict["description"])
            self.image_url = String.stringFromAnyObject(dict["image_url"])
        }
    }
    func loadPhoto(imageId:Int) {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfiguration)
        let url = NSURL(string: "https://api.500px.com/v1/photos/\(imageId)?consumer_key=7iL5EFteZ0j3OexGdDxnPANksfPwQZtD5SPaZhne")!
        let task = session.dataTaskWithURL(url) { (data, _, error) in
            if let error = error {
                NSLog("error:%@", error)
            }
            if let data = data {
                if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) {
                    if let photo_dict = json["photo"] as? [String:AnyObject], image_url = photo_dict["image_url"] as? String{
                        let url = NSURL(string: image_url)!
                        dispatch_sync(dispatch_get_main_queue(), { 
                            self.imageView.aw_downloadImageURL(url, showLoading: true, completionBlock: { (_, _) in
                                
                            })    
                        })
                        
                    }
                }
            }
        }
        task.resume()
    }
    
}