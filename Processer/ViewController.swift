//
//  ViewController.swift
//  Processer
//
//  Created by Woody Liu on 2023/2/2.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    let viewModel = SignInViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        
        viewModel.publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [unowned self] states in
                switch states.stauts {
                case .ready:
                    activityView.stopAnimating()
                case .isSignIning:
                    activityView.startAnimating()
                case .didSignIn(user: let user):
                    activityView.stopAnimating()
                    self.present(UserViewController(user: user), animated: true)
                case .error(_):
                    activityView.stopAnimating()
                }
            }).store(in: &bag)
    }
    
    @objc func appleSignIn() {
        viewModel.send(.appleSignIn)
    }
    
    @objc func emailSignIn() {
        viewModel.send(.emailSignIn("ABC@example.com", "1234567"))
    }
    
    private let appleBtn = UIButton()
    
    private let emailBtn = UIButton()
    
    private var bag = Set<AnyCancellable>()
    
    private let activityView: UIActivityIndicatorView = {
        let act = UIActivityIndicatorView(style: .large)
        act.tintColor = .blue
        return act
    }()
    
    fileprivate func setUI() {
    
        let hstack = UIStackView()
        hstack.axis = .horizontal
        hstack.distribution = .fillEqually
        hstack.alignment = .fill
        
        view.addSubview(hstack)
        hstack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hstack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hstack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hstack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            hstack.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        hstack.spacing = 20
        
        hstack.addArrangedSubview(appleBtn)
        hstack.addArrangedSubview(emailBtn)
        
        appleBtn.setTitle("Apple Sign In", for: .normal)
        appleBtn.setTitleColor(.black, for: .normal)
        emailBtn.setTitle("Email Sign In", for: .normal)
        emailBtn.setTitleColor(.black, for: .normal)

        appleBtn.addTarget(self, action: #selector(appleSignIn), for: .touchUpInside)
        emailBtn.addTarget(self, action: #selector(emailSignIn), for: .touchUpInside)
        
        view.addSubview(activityView)
        activityView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityView.topAnchor.constraint(equalTo: view.topAnchor),
            activityView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            activityView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            activityView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}

class UserViewController: UIViewController {
    
    let label = UILabel()

    convenience init(user: User) {
        self.init(nibName: nil, bundle: nil)
        self.user = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        label.text = "name: \(user.name ?? "now name")\n email: \(user.email)"
    }

    private var user: User!

}
