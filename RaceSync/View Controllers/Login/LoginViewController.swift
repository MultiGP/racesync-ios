//
//  LoginViewController.swift
//  RaceSync
//
//  Created by Ignacio Romero Zurbuchen on 2019-10-23.
//  Copyright © 2019 MultiGP Inc. All rights reserved.
//

import UIKit
import RaceSyncAPI
import SnapKit
import SwiftValidators
import RaceSyncAPI

class LoginViewController: UIViewController {

    // MARK: - Private Variables

    fileprivate lazy var loginFormView: UIView = {
        let view = UIView()
        view.alpha = 0
        view.backgroundColor = Color.clear
        view.addSubview(self.titleLabel)
        view.addSubview(self.emailField)
        view.addSubview(self.passwordField)
        view.addSubview(self.passwordRecoveryButton)
        view.addSubview(self.createAccountButton)
        view.addSubview(self.loginButton)
        view.addSubview(self.legalButton)
        return view
    }()

    fileprivate lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = titleText
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = Color.gray200
        return label
    }()

    fileprivate lazy var emailField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .next
        textField.textContentType = .emailAddress
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        return textField
    }()

    fileprivate lazy var passwordField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.placeholder = "Password"
        textField.keyboardType = .`default`
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .`continue`
        textField.textContentType = .password
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        return textField
    }()

    fileprivate lazy var passwordRecoveryButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(Color.red, for: .normal)
        button.setTitle("Forgot your password?", for: .normal)
        button.addTarget(self, action:#selector(didPressPasswordRecoveryButton), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(Color.red, for: .normal)
        button.setTitle("Create an account", for: .normal)
        button.addTarget(self, action:#selector(didPressCreateAccountButton), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var loginButton: ActionButton = {
        let button = ActionButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        button.setTitleColor(Color.blue, for: .normal)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = Color.white.withAlphaComponent(0.7)
        button.layer.cornerRadius = Constants.padding/2
        button.layer.borderColor = Color.gray100.cgColor
        button.layer.borderWidth = 0.5
        button.addTarget(self, action:#selector(didPressLoginButton), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var legalButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action:#selector(didPressLegalButton), for: .touchUpInside)

        let link = "Terms of Use"
        let label = "By tapping “Login” you will accept our " + link + "."

        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                          NSAttributedString.Key.foregroundColor: Color.gray200]

        let linkAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .medium),
                          NSAttributedString.Key.foregroundColor: Color.red]

        let attributedString = NSMutableAttributedString(string: label, attributes: attributes)
        attributedString.setAttributes(linkAttributes, range: NSString(string: label).range(of: link))
        button.setAttributedTitle(attributedString, for: .normal)

        return button
    }()

    @IBOutlet fileprivate weak var racesyncLogoView: UIImageView!
    @IBOutlet fileprivate weak var racesyncLogoViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var racesyncLogoViewOriginY: NSLayoutConstraint!

    @IBOutlet fileprivate weak var mgpLogoView: UIImageView!
    @IBOutlet fileprivate weak var mgpLogoLabel: UILabel!

    fileprivate var loginFormViewCenterYConstraint: Constraint?
    fileprivate var loginFormViewCenterYConstant: CGFloat = 0

    fileprivate var racesyncLogoHeightConstant: CGFloat = 0
    fileprivate var isKeyboardVisible: Bool = false

    fileprivate var authApi = AuthApi()
    fileprivate var shouldShowForm: Bool {
        get { return loginFormView.superview == nil }
    }

    fileprivate var titleText: String? {
        return APIServices.shared.settings.isDev ? "Login with a dev.MultiGP account" : "Login with a MultiGP account"
    }

    fileprivate enum Constants {
        static let padding: CGFloat = UniversalConstants.padding
        static let loginFormHeight: CGFloat = 320
        static let actionButtonHeight: CGFloat = 50
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !APIServices.shared.isLoggedIn {
            if shouldShowForm {
                setupLayout()
            } else {
                // resetting API object, for when logging out
                authApi = AuthApi()

                // resetting title label, in case of env switch
                titleLabel.text = titleText
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("Login Did Appear") // used to detect whenever the sim launched but they keyboard isn't visible

        // Skip login if there's a persisted sessionId
        if APIServices.shared.isLoggedIn {
            presentHome()
        } else {
            // Pre-populate development credentials, if applicable
            emailField.text = APIServices.shared.credential.email
            passwordField.text = APIServices.shared.credential.password

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(250)) {
                self.emailField.becomeFirstResponder()
            }
        }
    }

    // MARK: - Layout

    fileprivate func setupLayout() {

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        view.addGestureRecognizer(tapGestureRecognizer)

        view.insertSubview(loginFormView, belowSubview: racesyncLogoView)
        loginFormView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.leading.equalToSuperview().offset(Constants.padding)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
            $0.height.greaterThanOrEqualTo(Constants.loginFormHeight)

            loginFormViewCenterYConstraint = $0.centerY.equalToSuperview().constraint
            loginFormViewCenterYConstraint?.activate()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.top.trailing.equalToSuperview()
        }

        emailField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.padding*1.5)
            $0.leading.equalToSuperview().offset(Constants.padding/2)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }

        passwordField.snp.makeConstraints {
            $0.top.equalTo(emailField.snp.bottom).offset(Constants.padding*2)
            $0.leading.equalToSuperview().offset(Constants.padding/2)
            $0.trailing.equalToSuperview().offset(-Constants.padding)
        }

        func addline(under view: UIView) {
            let separatorLine = UIView()
            separatorLine.backgroundColor = Color.gray100
            loginFormView.addSubview(separatorLine)
            separatorLine.snp.makeConstraints {
                $0.top.equalTo(view.snp.bottom).offset(Constants.padding/2)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }

        addline(under: emailField)
        addline(under: passwordField)

        passwordRecoveryButton.snp.makeConstraints {
            $0.top.equalTo(passwordField.snp.bottom).offset(Constants.padding*1.5)
            $0.leading.equalToSuperview()
        }

        createAccountButton.snp.makeConstraints {
            $0.top.equalTo(passwordRecoveryButton.snp.bottom).offset(Constants.padding/2)
            $0.leading.equalToSuperview()
        }

        loginButton.snp.makeConstraints {
            $0.top.equalTo(createAccountButton.snp.bottom).offset(Constants.padding)
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.height.equalTo(Constants.actionButtonHeight)
        }

        legalButton.snp.makeConstraints {
            $0.top.equalTo(loginButton.snp.bottom).offset(Constants.padding/2)
            $0.centerX.equalToSuperview()
        }

        UIView.addParallaxToView(loginFormView)
        UIView.addParallaxToView(racesyncLogoView)
        UIView.addParallaxToView(mgpLogoLabel)
        UIView.addParallaxToView(mgpLogoView)
    }

    // MARK: - Actions

    @objc func didTapView(_ sender: UITapGestureRecognizer) {
        if emailField.isFirstResponder {
            emailField.resignFirstResponder()
        }
        if passwordField.isFirstResponder {
            passwordField.resignFirstResponder()
        }
    }

    @objc func didPressPasswordRecoveryButton() {
        WebViewController.openUrl(AppWebConstants.passwordReset)
    }

    @objc func didPressCreateAccountButton() {
        WebViewController.openUrl(AppWebConstants.accountRegistration)
    }

    @objc func didPressLoginButton() {
        shouldLogin()
    }

    @objc func didPressLegalButton() {
        WebViewController.openUrl(AppWebConstants.termsOfUse)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard !isKeyboardVisible else { return }
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        let keyboardRect = keyboardFrame.cgRectValue

        let intersection = keyboardRect.intersection(loginFormView.frame)

        loginFormViewCenterYConstant = intersection.height
        racesyncLogoHeightConstant = loginFormView.frame.minY - (intersection.height + Constants.padding*3)
        let racesyncLogoAlpha: CGFloat = 1

        UIView.animate(withDuration: animationDuration,
                       animations: {
                        self.loginFormViewCenterYConstraint?.update(offset: -self.loginFormViewCenterYConstant)
                        self.loginFormView.alpha = 1
                        self.view.layoutIfNeeded()
        },
                       completion: nil)

        guard racesyncLogoViewOriginY.constant != 0 else { return }

        UIView.animate(withDuration: animationDuration,
                       animations: {
                        self.racesyncLogoViewOriginY.constant = 0
                        self.racesyncLogoViewHeight.constant = self.racesyncLogoHeightConstant
                        self.racesyncLogoView.alpha = racesyncLogoAlpha
                        self.view.layoutIfNeeded()
        },
                       completion: nil)

        isKeyboardVisible = true
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        guard isKeyboardVisible else { return }
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        let racesyncLogoViewOriginYConstant = loginFormViewCenterYConstant/2
        loginFormViewCenterYConstant = 0

        UIView.animate(withDuration: animationDuration,
                       animations: {
                        self.loginFormViewCenterYConstraint?.update(offset: 0)
                        self.racesyncLogoViewOriginY.constant = racesyncLogoViewOriginYConstant

                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
        },
                       completion: nil)

        isKeyboardVisible = false
    }

    // MARK: - Events

    func shouldLogin() {
        guard let email = emailField.text else { shakeLoginButton(); return }
        guard Validator.isEmail().apply(email) else { shakeLoginButton(); return }

        guard let password = passwordField.text else { shakeLoginButton(); return }
        guard !Validator.isEmpty().apply(password) else { shakeLoginButton(); return }

        // Invalidate the form momentairly
        freezeLoginForm()
        loginButton.isLoading = true

        // Login
        authApi.login(email, password: password) { [weak self] (status, error) in
            if let error = error {
                self?.freezeLoginForm(false)
                AlertUtil.presentAlertMessage(error.localizedDescription, title: "Error")
            } else if status {
                self?.presentHome(transition: .flipHorizontal)
            }
            self?.loginButton.isLoading = false
        }
    }

    // MARK: - Transitions

    func shakeLoginButton() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.4
        animation.values = [-20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        loginButton.layer.add(animation, forKey: "shake")
    }

    func freezeLoginForm(_ freeze: Bool = true) {
        emailField.isUserInteractionEnabled = !freeze
        passwordField.isUserInteractionEnabled = !freeze
        passwordRecoveryButton.isUserInteractionEnabled = !freeze
        createAccountButton.isUserInteractionEnabled = !freeze
        loginButton.isUserInteractionEnabled = !freeze
        legalButton.isUserInteractionEnabled = !freeze
    }

    func presentHome(transition: UIModalTransitionStyle = .crossDissolve) {
        let viewController = HomeController.homeViewController()
        viewController.modalTransitionStyle = transition
        viewController.modalPresentationStyle = .fullScreen

        present(viewController, animated: true) { [weak self] in
            self?.loginButton.isLoading = false
            self?.freezeLoginForm(false)

            self?.emailField.text = nil
            self?.passwordField.text = nil
        }
    }
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        //
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        //
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didPressLoginButton()
        }

        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {

        // reset value of each other text field
        if textField == emailField, let txt = passwordField.text, txt.count > 0 {
            passwordField.text = ""
        }
        if textField == passwordField, let txt = emailField.text, txt.count > 0 {
            emailField.text = ""
        }

        return true
    }
}
