//
//  PhotosListViewController.swift
//  AWebImage
//
//  Created by 秦 道平 on 16/6/2.
//  Copyright © 2016年 秦 道平. All rights reserved.
//

import UIKit
import AWebImage

private let reuseIdentifier = "cell-image"

class PhotosListViewController: UICollectionViewController {
    
    var photos : PhotoListPaged? = nil
    var loadingLabel : UILabel!
    var loading : Bool = false {
        didSet {
            let loadingHeight : CGFloat = 30.0
            DispatchQueue.main.async { [weak self] () -> () in
                if let _self = self, let _collectionView = _self.collectionView {
                    var contentInset = _collectionView.contentInset
                    if _self.loading {
                        contentInset.bottom = loadingHeight
                        _collectionView.contentInset = contentInset
                        _self.loadingLabel = UILabel()
                        _self.loadingLabel.text = "loading..."
                        _self.loadingLabel.textAlignment = .center
                        _self.loadingLabel.font = UIFont.systemFont(ofSize: 14.0)
                        _self.loadingLabel.textColor = UIColor.lightGray
                        _self.loadingLabel.frame = CGRect(x: 0.0,
                                                              y: _collectionView.contentSize.height,
                                                              width: _collectionView.contentSize.width, height: loadingHeight)
                        _collectionView.addSubview(_self.loadingLabel)
                    }
                    else {
                        contentInset.bottom = 0.0
                        _collectionView.contentInset = contentInset
                        _self.loadingLabel.removeFromSuperview()
                    }
                }
                else {
                    NSLog("loading error")
                }
            }
            
        }
    }
    let imageProcess = AWebRoundImageProcess(cornerRadius: 10.0)
//    let imageProcess = AWebCircleImageProcess()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = true

        // Register cell classes
//        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
            let screen_width = UIScreen.main.bounds.width
            let item_width : CGFloat = (screen_width - 2.0) / 3.0
            let item_height  = item_width
            layout.itemSize = CGSize(width: item_width, height: item_height)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage.aw_imageWithColor(UIColor.white), for: .default)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.photos == nil {
            self.loadPhotos(true)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        guard let _photos = self.photos else {
            return
        }
        if segue.identifier == "segue_list_detail" {
            if let detailViewController = segue.destination as? PhotoDetailViewController {
                if let cell = sender as? UICollectionViewCell {
                    if let index_path = self.collectionView?.indexPath(for: cell) {
                        let photo = _photos.items[(index_path as NSIndexPath).row]
                        detailViewController.imageId = photo.id
                    }
                }
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos?.items.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let photos = self.photos {
            let photo = photos.items[(indexPath as NSIndexPath).row]
            if let imageView = cell.contentView.viewWithTag(1) as? UIImageView {
                imageView.image = nil
//                imageView.aw_downloadImageURL(photo.imageURL, showLoading: true, completionBlock: { (_, _) in
//                    
//                })
                imageView.aw_downloadImageURL_delay(photo.imageURL,
                                                    showloading: true,
                                                    withImageProcess: self.imageProcess,
                                                    completionBlock: { (_, _) in
                    
                })
            }
        }
        return cell
    }
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !self.loading else {
            return
        }
//        NSLog("scroll:%@", NSStringFromCGPoint(scrollView.contentOffset))
        if scrollView.contentOffset.y + scrollView.bounds.size.height >= scrollView.contentSize.height {
            self.loadPhotos()
        }
        
    }
}

extension PhotosListViewController {
    struct PhotoListItem {
        var id : Int!
        var name : String!
        var image_url : String!
        var image_format : String!
        var imageURL: URL!
        init(dict:[String:AnyObject]) {
            self.id = Int.valueFromAnyObject(dict["id"])
            self.name = String.stringFromAnyObject(dict["name"])
            self.image_url = String.stringFromAnyObject(dict["image_url"])
            self.image_format = String.stringFromAnyObject(dict["image_format"])
            self.imageURL = URL(string: self.image_url)
        }
    }
    struct PhotoListPaged {
        var current_page : Int! = 0
        var total_pages : Int! = 0
        var total_items : Int! = 0
        var items : [PhotoListItem]! = []
        mutating func updateFromDict(_ dict:[String:AnyObject]) {
            self.current_page = Int.valueFromAnyObject(dict["current_page"])
            self.total_pages = Int.valueFromAnyObject(dict["total_pages"])
            self.total_items = Int.valueFromAnyObject(dict["total_items"])
            if let photos_json_list = dict["photos"] as? [[String:AnyObject]]{
                let more_items = photos_json_list.map({ (photo_json) -> PhotoListItem in
                    return PhotoListItem(dict: photo_json)
                })
                self.items = self.items + more_items
            }
        }
    }
    fileprivate func loadPhotos(_ reload : Bool = false) {
        if self.photos == nil {
            self.photos = PhotoListPaged()
            self.collectionView?.reloadData()
        }
        guard let photos = self.photos else {
            return
        }
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration)
        let page = photos.current_page + 1
        let url = URL(string: "https://api.500px.com/v1/photos?feature=editors&page=\(page)&consumer_key=7iL5EFteZ0j3OexGdDxnPANksfPwQZtD5SPaZhne")!
        NSLog("url:\(url.absoluteString)")
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request, completionHandler: { [weak self](data, response, error) in
            if let data = data {
                if let json = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)) as? [String:AnyObject] {
                    DispatchQueue.main.async(execute: {
                        self?.loading = false
                        let oldTotal = self?.photos?.items.count ?? 0
                        self?.photos?.updateFromDict(json)
//                        self?.collectionView?.reloadData()
                        let newTotal = self?.photos?.items.count ?? 0
                        var index_path_to_insert : [IndexPath] = []
                        for a in oldTotal ..< newTotal {
                            index_path_to_insert.append(IndexPath(row: a, section: 0))
                        }
                        self?.collectionView?.insertItems(at: index_path_to_insert)
                    })
                    
                }
            }
        }) 
        self.loading = true
        task.resume()
    }
}
