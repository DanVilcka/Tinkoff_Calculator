//
//  ViewController.swift
//  TinkoffCalculator
//
//  Created by Daniil Vilchinskiy on 25.02.2024.
//

import UIKit

enum CalculationError: Error {
    case dividedByZero
}

enum Operation: String {
    case add = "+"
    case substract = "-"
    case multily = "x"
    case divide = "/"
    
    func calculate(_ number1: Double, _ number2: Double) throws -> Double {
        switch self {
        case .add:
            return number1 + number2
        case .substract:
            return number1 - number2
        case .multily:
            return number1 * number2
        case .divide:
            if number2 == 0 {
                throw CalculationError.dividedByZero
            }
            return number1 / number2
        }
    }
}

enum CalculationHistoryItem {
    case number(Double)
    case operation(Operation)
}

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var historyButton: UIButton!
    
    var calculatingHistory : [CalculationHistoryItem] = []
    var calculations: [Calculation] = []
    
    
    let calculationHistoryStorage = CalculationHistoryStorage()
    
    var alertView: AlertView = {
        let screenBoundes = UIScreen.main.bounds
        let alertHeight: CGFloat = 100
        let alertWidht: CGFloat = screenBoundes.width - 40
        let x: CGFloat = screenBoundes.width / 2 - alertWidht / 2
        let y: CGFloat = screenBoundes.height / 2 - alertHeight / 2
        let alertFrame = CGRect(x: x, y: y, width: alertWidht, height: alertHeight)
        let alertView = AlertView(frame: alertFrame)
        return alertView
    }()
    
    lazy var numberFormatter: NumberFormatter = {
        var numberFormatter = NumberFormatter()
        
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.locale = Locale(identifier: "ru_RU")
        numberFormatter.numberStyle = .decimal
        
        return numberFormatter
    }()
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let textButton = sender.titleLabel?.text else { return }
        
        if textButton == "," && label.text?.contains(",") == true {
            return
        }
        
        if label.text == "0" && textButton != "," {
            label.text = textButton
        } else {
            label.text?.append(textButton)
        }
        
        if label.text == "3,141592" {
            animateAlert()
        }
        
        sender.animatedTap()
    }
    
    @IBAction func operationbuttonPressed(_ sender: UIButton) {
        guard
            let textButton = sender.titleLabel?.text,
            let buttonOperation = Operation(rawValue: textButton)
        else {
            return
        }
        
        guard
            let textLabel = label.text,
            let textNumber = numberFormatter.number(from: textLabel)?.doubleValue
        else {
            return
        }
        
        calculatingHistory.append(.number(textNumber))
        calculatingHistory.append(.operation(buttonOperation))
        
        resetTextLabel()
    }
    
    @IBAction func clearbuttonPressed() {
        calculatingHistory.removeAll()
        
        resetTextLabel()
        
    }
    
    @IBAction func calculatebuttonPressed() {
        guard
            let textLabel = label.text,
            let textNumber = numberFormatter.number(from: textLabel)?.doubleValue
        else {
            return
        }
        
        calculatingHistory.append(.number(textNumber))
        
        do {
            let result = try calculate()
            
            label.text = numberFormatter.string(from: NSNumber(value: result))
            let newCalculation = Calculation(expression: calculatingHistory, result: result)
            calculations.append(newCalculation)
            calculationHistoryStorage.setHistory(calculation: calculations)
        } catch {
            label.text = "Ошибка"
            label.shake()
        }
        
        calculatingHistory.removeAll()
    }
    
    @IBAction func showCalculationsList(_ sender: Any) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let calculationsVS = sb.instantiateViewController(withIdentifier: "CalculationsListViewController")
        if let vc = calculationsVS as? CalculationsListViewController {
            vc.calculations = calculations
        }

        navigationController?.pushViewController(calculationsVS, animated: true)
    }
    
    
    func calculate() throws -> Double {
        guard case .number(let firstNumber) = calculatingHistory[0] else { return 0 }
        
        var currentResult = firstNumber
        
        for index in stride(from: 1, to: calculatingHistory.count - 1, by: 2) {
            guard 
                case .operation(let operation) = calculatingHistory[index],
                case .number(let number) = calculatingHistory[index + 1]
            else {
                break
            }
            currentResult = try operation.calculate(currentResult, number)
        }
        
        return currentResult
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        resetTextLabel()
        
        calculations = calculationHistoryStorage.loadHistory()
        
        
        view.addSubview(alertView)
        alertView.alpha = 0
        alertView.alertText = "Вы нашли пасхалку!"
        
        view.subviews.forEach {
            if type(of: $0) == UIButton.self {
                $0.layer.cornerRadius = 20
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func resetTextLabel() {
        label.text = "0"
    }
    
    func animateAlert() {
        if !view.contains(alertView) {
            alertView.alpha = 0
            alertView.center = view.center
            view.addSubview(alertView)
        }
        
        UIView.animateKeyframes(withDuration: 2.0, delay: 0.5) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.alertView.alpha = 1
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                var newCenter = self.label.center
                newCenter.y -= self.alertView.bounds.height
                self.alertView.center = newCenter
            }
        }
    }
}

extension UILabel {
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.05
        animation.repeatCount = 5
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5, y: center.y))
        
        layer.add(animation, forKey: "position")
    }
}

extension UIButton {
    
    func animatedTap() {
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, 0.9, 1]
        scaleAnimation.keyTimes = [0, 0.2, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0.4, 0.8, 1]
        opacityAnimation.keyTimes = [0, 0.2, 1]
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 1.5
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        
        layer.add(animationGroup, forKey: "animationGroup")
    }
}
