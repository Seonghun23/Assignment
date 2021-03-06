//
//  MainTabBarController.swift
//  Assignment
//
//  Created by 고상범 on 2018. 12. 7..
//  Copyright © 2018년 고상범. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    var movieInformations: [MovieInformation] = []
    var sortCode: SortCode = SortCode.reservationRate
    
    lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setIndicator()
        navigationItemUpdate()
        indicator.startAnimating()
        setInitialNetworkData()
       
    }
    
   private func buildViewControllers() {
        let tableViewController = MainTableViewController()
        tableViewController.tabBarItem = UITabBarItem(title: "Table", image: #imageLiteral(resourceName: "ic_table"), tag: 0)
        tableViewController.tableView.backgroundColor = UIColor.white
        tableViewController.movieInformations = self.movieInformations
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        let collectionViewController: MainCollectionViewController = MainCollectionViewController(collectionViewLayout: layout)
        collectionViewController.tabBarItem = UITabBarItem(title: "Collection", image: #imageLiteral(resourceName: "ic_collection"), tag: 1)
        collectionViewController.collectionView?.backgroundColor = UIColor.white
        collectionViewController.movieInformations = self.movieInformations

        let viewControllers = [tableViewController, collectionViewController]
        self.setViewControllers(viewControllers, animated: false)
    }
    
   private func setIndicator() {
        self.view.addSubview(indicator)
        self.indicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        self.indicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    }
}

//MARK:- NavigationItem Setting
extension MainTabBarController {
    
   private func navigationItemUpdate() {
        self.navigationItem.title = "예매율순"
        let settingButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_settings"), style: .plain, target: self, action: #selector(settingButtonPressed))
        self.navigationItem.rightBarButtonItem = settingButton
    }
    
    @objc func settingButtonPressed() {
        let alertController: UIAlertController = UIAlertController(title: "정렬방식 선택",message: "영화를 어떤 순서로 정렬할까요?",preferredStyle: .actionSheet)
        let reservationRateAction: UIAlertAction = UIAlertAction(title: "예매율", style: .default, handler: {(action: UIAlertAction) in self.navigationItem.title = "예매율순"
            self.indicator.startAnimating()
            self.fetchMovieInformation(by: .reservationRate) {
                
                self.updateFromModel(viewControllers: self.viewControllers ?? [UIViewController.init()])
                
            }
            
        })

        let qurationAction: UIAlertAction = UIAlertAction(title: "큐레이션", style: .default, handler: {(action: UIAlertAction) in
            self.navigationItem.title = "큐레이션"
            self.indicator.startAnimating()
            self.fetchMovieInformation(by: .quration) {
                
                self.updateFromModel(viewControllers: self.viewControllers ?? [UIViewController.init()])
            
            }
            })
        
        let outDateAction: UIAlertAction = UIAlertAction(title: "개봉일", style: .default, handler: {(action: UIAlertAction) in
            self.navigationItem.title = "개봉일순"
            self.indicator.startAnimating()
            self.fetchMovieInformation(by: .outDate) {
                
                self.updateFromModel(viewControllers: self.viewControllers ?? [UIViewController.init()])
            }
        })
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alertController.addAction(reservationRateAction)
        alertController.addAction(qurationAction)
        alertController.addAction(outDateAction)
        alertController.addAction(cancelAction)
        
        if UI_USER_INTERFACE_IDIOM() == .pad { //아이패드일 경우 액션시트를 대체해서 사용된다.
            alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            alertController.popoverPresentationController?.permittedArrowDirections = .up
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.present(alertController, animated: true, completion: nil)
        }
    
    }
    
//MARK:- Networking and data Setting
   private func setInitialNetworkData() {
        let request = NetworkManager.shared.requestBuilder.makeRequest(form: MovieAPI.movieList(sortBy: sortCode), errorOcurredBlock: {
            self.present(ErrorHandler.shared.buildErrorAlertController(error: APIError.urlFailure), animated: true, completion: nil)
        })
        NetworkManager.shared.fetch(with: request, decodeType: APIResponseMovieInformation.self) { [weak self] (result, response) in
            
            switch result {
            case .success(let data):
                self?.movieInformations = data.movies
                 DispatchQueue.main.async {
                    self?.indicator.stopAnimating()
                    self?.buildViewControllers()
                }
                
            case.failure(_ ):
                self?.present(ErrorHandler.shared.buildErrorAlertController(error: APIError.requestFailed),
                              animated: true,
                              completion: nil)
            }
        }
    }
    
    
    private func updateFromModel(viewControllers: [UIViewController]) {
        guard let tableView = self.viewControllers?[0] as? MainTableViewController,
            let collectionView = self.viewControllers?[1] as? MainCollectionViewController else {
                
                return
        }
        tableView.movieInformations = self.movieInformations
        collectionView.movieInformations = self.movieInformations
    }
        
    private func fetchMovieInformation(by sortCode: SortCode, _ completion: @escaping ()->()) {
        let request = NetworkManager.shared.requestBuilder.makeRequest(form: MovieAPI.movieList(sortBy: sortCode), errorOcurredBlock: {
            
            self.present(ErrorHandler.shared.buildErrorAlertController(error: APIError.urlFailure), animated: true, completion: nil)
            
        })
            NetworkManager.shared.fetch(with: request, decodeType: APIResponseMovieInformation.self) { [weak self] (result, response) in
                switch result {
                case .success(let data):
                    self?.movieInformations = data.movies
                    OperationQueue.main.addOperation {
                        self?.indicator.stopAnimating()
                        completion()
                    }
                case.failure( _):
                     DispatchQueue.main.async {
                        self?.indicator.stopAnimating()
                        self?.present(ErrorHandler.shared.buildErrorAlertController(error: APIError.requestFailed), animated: true, completion: nil)
                    }
                }
            }
    }
}

