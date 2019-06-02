//
//  GradientPolylineRenderer.swift
//  IoT_Respirator
//
//  Created by Alexander Luisi on 01/06/2019.
//  Copyright © 2019 Alexander Luisi. All rights reserved.
//
// Adapted for use from https://stackoverflow.com/a/53126528 accessed on 01/06/2019

import Foundation
import MapKit

class GradientPolylineRenderer: MKPolylineRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let boundingBox = self.path.boundingBox
        let mapRectCG = rect(for: mapRect)
        
        if(!mapRectCG.intersects(boundingBox)) { return }
        
        
        var prevColor: CGColor?
        var currentColor: CGColor?
        
        guard let polyLine = self.polyline as? GradientPolyline else { return }
        
        let path = UIBezierPath() //CGMutablePath()
        
        for index in 0...self.polyline.pointCount - 1{
            let point = self.point(for: self.polyline.points()[index])
            
            currentColor = polyLine.getHue(from: index)
            
            if index == 0 {
                path.move(to: point)
            } else {
                let prevPoint = self.point(for: self.polyline.points()[index - 1])
                path.move(to: prevPoint)
                path.addLine(to: point)
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                
                let colors = [prevColor!, currentColor!] as CFArray
                let baseWidth = self.lineWidth / zoomScale
                
                context.saveGState()
                context.addPath(path.cgPath)
                
                let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1])
                
                context.setLineWidth(baseWidth)
                context.setLineJoin(.round)
                
                context.setLineCap(.round)
                context.replacePathWithStrokedPath()
                context.clip()
                context.drawLinearGradient(gradient!, start: prevPoint, end: point, options: [])
                context.restoreGState()
            }
            prevColor = currentColor
        }
 
    }
    
    
    // Adapted for use from: https://stackoverflow.com/a/55690893
    // and https://code.tutsplus.com/tutorials/smooth-freehand-drawing-on-ios--mobile-13164
    // Accessed on 02/06/2019
    
    func midPointForPoints(from p1:CGPoint, to p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func controlPointForPoints(from p1:CGPoint,to p2:CGPoint) -> CGPoint {
        var controlPoint = midPointForPoints(from:p1, to: p2)
        let  diffY = abs(p2.y - controlPoint.y)
        if p1.y < p2.y {
            controlPoint.y = controlPoint.y + diffY
        } else if ( p1.y > p2.y ) {
            controlPoint.y = controlPoint.y - diffY
        }
        return controlPoint
    }
    
    
    
}
