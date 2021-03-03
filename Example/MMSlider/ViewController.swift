//
//  ViewController.swift
//  MMSlider
//
//  Created by Monang Champaneri on 03/03/2021.
//  Copyright (c) 2021 Monang Champaneri. All rights reserved.
//

import UIKit
import MMSlider
class ViewController: UIViewController {

    @IBOutlet weak var Slider: MMSlider!
    var isChangeTerminal: Bool = true
    var sliderValuesArray: [CGFloat] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        Slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        Slider.addTarget(self, action: #selector(sliderToucheOut(_:)), for: .touchUpInside)
        Slider.minimumValue = 0
        Slider.maximumValue = 100
        Slider.defaultValue = 75
        Slider.orientation = .horizontal
        Slider.value = [0, 0, 0, 75, 100, 75.1]
        Slider.thumbViews[5].backgroundColor = .clear
        Slider.thumbViews[5].image = #imageLiteral(resourceName: "slider_thumb")
        Slider.disabledThumbIndices = [0, 4]
        Slider.valueLabelPosition = .top
        self.sliderValuesArray = Slider.value
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc func sliderChanged(_ slider: MMSlider) {
        print("\(slider.value)")

    }
    @objc func sliderToucheOut(_ slider: MMSlider) {
        
        let dragThumb: CGFloat = slider.value[5]
        if slider.value[1] == 0 {
            slider.value[1] = dragThumb
            sliderValuesArray = slider.value
        } else if slider.value[2] == 0 {
            slider.value[2] = dragThumb
            sliderValuesArray = slider.value
        } else {
            var ValuesFilter: [CGFloat] = slider.value
            print(ValuesFilter)
            ValuesFilter.remove(at: 5)
            self.BlinkingAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                sliderValuesArray[5] = dragThumb
                print(sliderValuesArray)
                Slider.value[5] = dragThumb
            }
        }
    }
    func findClosest(_ values: [CGFloat], _ givenValue: CGFloat) -> CGFloat {
        let sorted = values.sorted()
        let over = sorted.first(where: { $0 >= givenValue })!
        let under = sorted.last(where: { $0 <= givenValue })!
        let diffOver = over - givenValue
        let diffUnder = givenValue - under
        return (diffOver < diffUnder) ? over : under
    }
    func BlinkingAnimation(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            print(sliderValuesArray[5])
            Slider.value[5] = sliderValuesArray[5]
        }
        Slider.thumbViews[5].blink()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
            Slider.thumbViews[5].stopBlinking()
        }
    }

}

extension UIImageView{
        func blink() {
             self.alpha = 0.0;
            UIView.animate(withDuration: 0.1, //Time duration you want,
                 delay: 0.0,
                 options: [.curveEaseInOut, .autoreverse, .repeat],
                 animations: { [weak self] in self?.alpha = 1.0 },
                 completion: { [weak self] _ in self?.alpha = 1.0 })
         }
        func stopBlinking(){
                layer.removeAllAnimations()
                alpha = 1
        }
}
