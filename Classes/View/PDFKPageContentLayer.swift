//
//  PDFKPageContentLayer.swift
//  M13PDFKit
//
/*
Copyright (c) 2015 Brandon McQuilkin

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import UIKit
import QuartzCore

//The number of zoom levels
private let LEVELS_OF_DETAIL: Int = 16

/**
The tiled layer that renders the PDF page.
*/
internal class PDFKPageContentLayer: CATiledLayer {
    init() {
        super.init()
        
        levelsOfDetail = LEVELS_OF_DETAIL
        levelsOfDetailBias = LEVELS_OF_DETAIL - 1
        
        //Size of tiles
        let screenScale: CGFloat = UIScreen.mainScreen().scale
        let screenBounds: CGRect = UIScreen.mainScreen().bounds
        
        let pixelsW: CGFloat = screenBounds.size.width * screenScale
        let pixelsH: CGFloat = screenBounds.size.width * screenScale
        let max: CGFloat = pixelsW > pixelsH ? pixelsW : pixelsH
        let aTileSize: CGFloat = max < 512.0 ? 512.0 : 1024.0
        
        self.tileSize = CGSizeMake(aTileSize, aTileSize)
    }
}