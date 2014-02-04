#!/bin/bash

templatesDir='sbcTemplates'
headSVG="$templatesDir"'/decs-n-root.svg'
rectTemplate="$templatesDir"'/rectWithLabel.svg' # rectSet by N # 'rectXYC00.svg'
tailSVG="$templatesDir"'/tail.svg'

copyrightGPL='COPYING'

### Copyright 2014 Mark S. Kalusha (MSK) ### 
### DUAL Licsence ## GPLv3 or later, or Ruby License ###
### Templates can be CC-BY-SA XOR GPL ###
#
# This program, sbc (simpleBarCharter), and optionally
# the SVG template files listed above, under 'sbc/sbcTemplates',
# are free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# For a current copy of this programs source code find me as 'mstepk' on GitHub
# https://github.com/ => https://github.com/mstepk/sbc

workingDir=`pwd`
begDTStamp=`date +%Y%m%d_%H%M_%s` # 20140131_1948_1391219299
whoAmI=`whoami`
if test "$whoAmI" = "$USER"; then uUser="$whoAmI"; fi;

# Program previously named:
# ../bars/makeXRectsOfWidthW-givenListOfYRectHeights.sh (barChart)

sbcInstance='rectSet_DT-STAMP.svg'
rectangleSetOut="$templatesDir"'/derivatives/'
rectangleSetOutInstance="$rectangleSetOut$sbcInstance"
derivativesCache="$rectangleSetOut"'.cache/'
derivativesCacheInstance="$derivativesCache$sbcInstance"

# Colors are RGB (Red-Green-Blue), 256 based triples for about 256^3 
# Bar Colors are dynamically calculated/derived from the constants below:
baseR=8
baseG=13
baseB=5
colorModulus=255
rgbBaseMultiplier=10
rgbDeltaMultiplier=2

defaultAspectRatio="16:9"
arMultiplier=45 # Determines the scale-up factor in pixels.

# FIX-ME NOTE: The current implementation is limited to all 
# integer inputs.

# Integer input eases playing with resolution and scaling,
# due to its direct correspondence with pixels, but only 
# if we impose a restriction on screen size.
# Knowing the screen size ratio would be super for resetting the
# default defaultAspectRatio and arMultiplier. 

# Dealing with float or chart sizes greater then screen resolution,a
# or pixels available to the window, would require some multiplication 
# and rounding to handle decimal values.
# Another way might be to use fully float arithmetic in combination with 
# controlled rounding points.

# BUG 1: Labels on Bars, only minimal supported, display of labels is ugly in general,
#        though not too bad if only a single character label is used.

# FEATURE REQUEST 1: Control of Bar Colors
# => By making the the 1st argument a set of triples
#    we can allow easy control of the color of each bar
#    by passing the RGB value.

# FEATURE REQUEST 2: Bar orientation and bar order.
# => For order maybe go to quadruples instead of triples.
# => For orientation, allow toggling.
# => Add config for mobile so that toggling orientation can be triggered by
#    accelerometer, so graph toggles with device orientation.

# Future merge plans with spc (simplePieCharter):
# ======> Re-write simpleBarCharter in Ruby
#  =====> Re-write '../slices/addSegmentValues.sh', simplePieCharter, in Ruby
#   ====> Allow toggling between pie and bar views
#    ===> Make tactile * use rooted Android Pad for testing *
#     ==> Release spbc (simplePieBarCharter)
#      => APB - App Pie Bar, SCA - Simple Charter App, Chart "eQualizer"!? 80 #  

# plotWidth=720
# plotHeight=405

useMinimumPlotDims=1
slideRectsToBottomOfPlot=1

rectSpacing=5
xStartRect=10
yStartRect=10

# Used to dynamically determine label text size/height based on the height of plot 
chartLabelInverseFactor=12
barLabelInverseFactor=`expr $chartLabelInverseFactor \* 2`

# 'Bar Chart - Text Title'
chartLabelText=''
xChartLabelStart=$xStartRect
yChartLabelStart=$yStartRect
chartLabelPadding=$rectSpacing
printChartLabel=1

### BegUP => Usage and Parameters ----------------------------------------- ###
#
# This program uses several internal variables to allow making a bar chart
# with a minimum of user input.  Creating an SVG bar chart is as easy as
# calling/invoking this program with a list of integers.
#
# i.e. ./barChart "1 4 9 16 25 36 49"
# 
## Arg-1 => List of Bar Heigths ---------------------------------------------##
#  The 1st argument to this program is a quoted list of heigths, and is the
#  only required argument.
#
#  The height of the plot, the bar chart, is determined by using the maximum
#  value in the list of bar/rectangle heights that is passed by the user.
#
#  The width of the plot is determined using the height of the plot along with
#  the 'defaultAspectRatio', forcing the 'plotWidth' and 'plotHeight' to fit
#  the aspect ratio.
#
#   If you want to label your bars just add a semi-colon and label after each
#   height value in the list.  i.e. "20:A 15:B 54:C" 
# 
## Arg-2 => Bar Width or Chart Aspect Ratio -------------------------------- ##
#  If a specific/known width, or a different aspect ratio, is desired then it
#  can be provided by the user as the 2nd argument to this program.
#  i.e. 640 or 3:2
#
## Arg-3 => Title ---------------------------------------------------------- ##
#  Provide a quoted string as a 3rd argument to title your chart.
#
## Arg-4 => Y-Max (Headroom) ##
#  By default the maximum Y value of the chart is set equal to the max height
#  from the list of bar heights given in the 1st argument.  To set a higher
#  value for the maximum Y, and give your chart some headroom, pass your max-Y
#  as a 4th argument.
#
### EndUP => Usage and Parameters ----------------------------------------- ###

listOfRectHeigths="$1" # "$2" # "$4"
# $3 is Chart Title (chartLabelText)
dynamicWidthDeterminationBasedOnDefaultAspectRatio=1 # xOr $2
userMaxY=0 # xOr $4
if test $# -gt 1;
	then
		rectWidthOrAspectRatioInput="$2" # prev-$1 # prevPrev-$3
		hasColon=`printf '%s' "$rectWidthOrAspectRatioInput" | grep -ce ':'`
		if test $hasColon -eq 1;
			then
				xAspect=`printf '%s' "$rectWidthOrAspectRatioInput" | cut -d ':' -f 1`
				yAspect=`printf '%s' "$rectWidthOrAspectRatioInput" | cut -d ':' -f 2`
				defaultAspectRatio="$xAspect:$yAspect"
			else
				rectWidthInput="$rectWidthOrAspectRatioInput"
				if test "$rectWidthInput" = '' -o "$rectWidthInput" = '0' -o "$rectWidthInput" = 'dynamic';
					then  
						printf '\nDynamic rectWidth and plotWidth in effect (%s|%s)\n' "$rectWidthOrAspectRatioInput" "$defaultAspectRatio"
					else
						dynamicWidthDeterminationBasedOnDefaultAspectRatio=0
						rectWidth="$rectWidthInput"
				fi;
		fi;
		if test $# -gt 2;
			then
				chartLabelText="$3"
				if test $# -gt 3;
					then
						userMaxY=$4
						if test $# -gt 4;
							then
								plotWidth=$5 # originally-$1
								plotHeight=$5 # originally-$2
						fi;
				fi;
		fi;
	else
		printf '\nSingle argument provided, dynamic rectWidth and plotWidth in effect (%s).\n' "$defaultAspectRatio"
fi;

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then
		pi=$(echo "scale=10; 4*a(1)" | bc -l)
		arW=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 1` 
		arH=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 2`
		aspectRatioA=$(echo "$arW / $arH" | bc -l)
		aspectRatioB=$(echo "$arH / $arW" | bc -l)
fi; 

if test "$chartLabelText" = ''; then printChartLabel=0; fi; 

printf '\nTemplates (HEAD:BAR:TAIL) => (%s:%s:%s)\n' "$headSVG" "$rectTemplate" "$tailSVG" 
#printf '\nwidth: %i and heigths:' "$rectWidth" 
printf '\nRectangle/Bar Heigths:' 

minPlotWidth=`expr \( $xStartRect \* 2 \) + $rectSpacing`
minPlotHeight=`expr \( $yStartRect \* 2 \) + $rectSpacing`

maxY=0
numRects=0
barHeigths=''
barLabels=''
numLabels=0
for Y in $listOfRectHeigths;
	do
		numRects=`expr $numRects + 1`
		printf ' %s' "$Y"
		hasLabel=`printf '%s' "$Y" | grep -ce ':'`
		barHeight="$Y"
		if test $hasLabel -eq 1;
			then
				barHeight=`printf '%s' "$Y" | cut -d ':' -f 1`
				barLabel=`printf '%s' "$Y" | cut -d ':' -f 2`
				numLabels=`expr $numLabels + 1`
			else
				barLabel=''
				barHeight="$Y"
		fi;
		if test $numRects -eq 1;
			then
				barHeigths="$barHeight"
				barLabels="$barLabel"
			else
				barHeigths="$barHeigths $barHeight"
				barLabels="$barLabels $barLabel"
		fi;
		if test $barHeight -ge $maxY; then maxY=$barHeight; fi;
	done;

if test $userMaxY -ge $maxY; then maxY=$userMaxY; fi;
if test $maxY -gt 0; then minPlotHeight=`expr $maxY + \( $yStartRect \* 2 \)`; fi;

barLabelHeight=`expr $minPlotHeight / $barLabelInverseFactor`
barLabelsDisplay='none'
barLabelsOnTop=1

chartLabelHeight=`expr $minPlotHeight / $chartLabelInverseFactor`
yChartLabelStart=`expr $chartLabelHeight + $chartLabelPadding`
chartLabelDisplay='none'
if test $printChartLabel -eq 1;
	then
		printf '\nChart Label Text (%s), Chart Label Height (%i) ::: Num Bars (%i), Num Bar Labels (%i)\n' "$chartLabelText" "$chartLabelHeight" "$numRects" "$numLabels"
		chartLabelDisplay='block'
		if test $numLabels -eq 0;
			then
				minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $chartLabelPadding \* 2 \)`
			else
				barLabelsDisplay='block'
				if test $barLabelsOnTop -eq 0;
					then
						minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $chartLabelPadding \* 2 \) + $barLabelHeight + \( $chartLabelPadding \* 2 \)`
					else
						minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $chartLabelPadding \* 2 \)`
				fi;
		fi;
	else
		if test $numLabels -ge 1;
			then
				barLabelsDisplay='block'
				if test $barLabelsOnTop -eq 0;
					then
						minPlotHeight=`expr $minPlotHeight + $barLabelHeight + \( $chartLabelPadding \* 2 \)`
					else
						minPlotHeight=`expr $minPlotHeight`
				fi;
		fi;
fi;
#chartLabelHeight=`expr $minPlotHeight / $chartLabelInverseFactor`
#yChartLabelStart=`expr $chartLabelHeight + \( $chartLabelPadding \*2 \)`

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then 
		minPlotWidthFloat=$(echo "$minPlotHeight * $aspectRatioA" | bc -l)
		rectWidthFloat=$(echo "( $minPlotWidthFloat - ( $xStartRect * 2 ) ) / ( $numRects * 1.2 )" | bc -l)
		rectSpacingFloat=$(echo "$rectWidthFloat * 0.2" | bc -l)
		rectWidth=`printf '%s' "$rectWidthFloat" | cut -d '.' -f 1` #`expr $rectWidthFloat + 1`
		rectSpacing=`printf '%s' "$rectSpacingFloat" | cut -d '.' -f 1` #`expr $rectSpacingFloat - 1`
		printf '\nminPlotWidthFloat (%s) and rectWidthFloat (%s) and rectSpacingFloat (%s) dynamically determined based on defaultAspectRatio (%s) and maxY (%s).\n' "$minPlotWidthFloat" "$rectWidthFloat" "$rectSpacingFloat" "$defaultAspectRatio" "$maxY"
		if test "$rectSpacing" = ''; then rectSpacing=1; fi;
fi;

barLabelHeight=`expr $rectWidth / 2`

printf '\nRectangle Widths (all equal): %i' "$rectWidth"
minPlotWidth=`expr \( \( $rectWidth + $rectSpacing \) \* $numRects \) + \( $xStartRect \* 2 \) - $rectSpacing`

if test $useMinimumPlotDims -eq 1;
	then
		plotWidth="$minPlotWidth"
		plotHeight="$minPlotHeight"
fi;

printf '\nPlot Width (%s), Plot Height (%s)\n' "$plotWidth" "$plotHeight"

printf '\n%s\n' 'Building Rects/Bars ...'

i=0
rectSet=''
for Y in $barHeigths;
	do
		spacing=`expr $i \* $rectSpacing`
		shiftRight=`expr $i \* $rectWidth + $spacing`
		i=`expr $i + 1`
		printf '\n %i: Bar Height (%i)' "$i" "$Y"
		barLabelText=`printf '%s' "$barLabels" | cut -d ' ' -f $i`
		xBarLabelStart=`expr $xStartRect + $shiftRight + \( $rectSpacing \* 2 \)`
		if test $barLabelsOnTop -eq 1;
			then
				yBarLabelStart=`expr $plotHeight - $Y - $barLabelHeight`
			else
				yBarLabelStart=`expr $plotHeight - $barLabelHeight`
		fi;
		if test $slideRectsToBottomOfPlot -eq 1;
			then
				slideDown=`expr \( $plotHeight - $Y \) - \( $yStartRect \* 2 \)`
				yTrans=$slideDown
			else
				yTrans=0
		fi;
		delta=`expr $i \* $rgbDeltaMultiplier`
		red=`expr $baseR \* $rgbBaseMultiplier`
		red=`expr $red + $delta` 
		red=`expr $red % $colorModulus`
		green=`expr $baseG \* $rgbBaseMultiplier`
		green=`expr $green + $delta`
		green=`expr $green % $colorModulus`
		blue=`expr $baseB \* $rgbBaseMultiplier`
		blue=`expr $blue + $delta`
		blue=`expr $blue % $colorModulus`
		RGB='#'"$red$green$blue" # "s/cFill/$RGB/g"
		printf ', Bar Color => R(%i), G(%i), B(%i)' "$red" "$blue" "$green"
		RGB='rgb('"$red"', '"$green"', '"$blue"')'
		customRect=`sed -e "s/xStart/$xStartRect/g" -e "s/yStart/$yStartRect/g" -e "s/\"X\"/\"$rectWidth\"/g" -e "s/\"Y\"/\"$Y\"/g" -e "s/cFill/$RGB/g" -e "s/xTrans/$shiftRight/g" -e "s/yTrans/$yTrans/g" $rectTemplate` # -e "s/LABEL_DISPLAY/$barLabelsDisplay/g" $rectTemplate`
		customRect=`printf '%s\n' "$customRect" | sed -e "s/LABEL_TEXT/$barLabelText/g" -e "s/LABEL_HEIGHT/$barLabelHeight/g" -e "s/xLabelStart/$xBarLabelStart/g" -e "s/yLabelStart/$yBarLabelStart/g" -e "s/LABEL_DISPLAY/$barLabelsDisplay/g"` # -e "s/LABEL_PADDING/chartLabelPadding/g"`
		rectSet="$rectSet$customRect"
	done;

printf '\n%s\n' ''

svgHead=`sed -e "s/SVG_DOC_WIDTH/$plotWidth/g" -e "s/SVG_DOC_HEIGHT/$plotHeight/g" -e "s/CHART_DOC_WIDTH/$plotWidth/g" -e "s/CHART_DOC_HEIGHT/$plotHeight/g" $headSVG`
svgTail=`sed -e "s/LABEL_TEXT/$chartLabelText/g" -e "s/LABEL_HEIGHT/$chartLabelHeight/g" -e "s/xLabelStart/$xChartLabelStart/g" -e "s/yLabelStart/$yChartLabelStart/g" -e "s/LABEL_PADDING/chartLabelPadding/g" -e "s/LABEL_DISPLAY/$chartLabelDisplay/g" $tailSVG`
dtStamp=`date +%Y%m%d_%H%M_%s` # 20140129_1817_1391041044
printf '%s' "$svgHead$rectSet$svgTail" > $rectangleSetOutInstance
stampedRectSetSVG=`printf '%s' "$rectangleSetOutInstance" | sed -e "s/DT-STAMP/$dtStamp/g"`
stampedRectSetSVG_cache=`printf '%s' "$derivativesCacheInstance" | sed -e "s/DT-STAMP/$dtStamp/g"`

useDerivativeCaching=1
if test $useDerivativeCaching -eq 1;
	then
		if test ! -d $workingDir/$derivativesCache; then mkdir -vp $derivativesCache; fi;
		yourSimpleBarChart_SVG="$stampedRectSetSVG_cache"
	else
		yourSimpleBarChart_SVG="$stampedRectSetSVG"
fi;

printf '\nOutput written to rectangleSetOutInstance (%s):\n' "$rectangleSetOutInstance"
ls -lhAt $rectangleSetOutInstance | sed -e 's/^/\t/g'
file $rectangleSetOutInstance | sed -e 's/^/\t/g'
wc -l $rectangleSetOutInstance | sed -e 's/^/\t/g' -e 's/$/\n/g'

cp -vp $rectangleSetOutInstance $yourSimpleBarChart_SVG
YSBC="$workingDir/$yourSimpleBarChart_SVG"

tryDisplayingBarChartInABrowser=1
browserLauncher='launchBrowserWindowToDisplaySVG.sh'
geometry="$plotWidth"'x'"$plotHeight"
displays=1

if test $tryDisplayingBarChartInABrowser -eq 1;
	then
		if test -e $browserLauncher;
			then
				./$browserLauncher "$YSBC" "$yourSimpleBarChart_SVG" "$geometry" "$displays" &
		fi;
fi;

myProgram="$0"
SBC=`ls -lhAt $myProgram | cut -d ' ' -f 10-`
printf '\n\nThank you for using the simpleBarCharter, (sbc) => (%s), version 0.0.11\n\n' "$SBC"

exit 0;

