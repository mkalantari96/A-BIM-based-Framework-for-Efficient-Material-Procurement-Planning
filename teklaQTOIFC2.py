import ifcopenshell
import pyodbc
import datetime
import math       
import numpy as np



#unit normal vector of plane defined by points a, b, and c
def unit_normal(a, b, c):
    x = np.linalg.det([[1,a[1],a[2]],
             [1,b[1],b[2]],
             [1,c[1],c[2]]])
    y = np.linalg.det([[a[0],1,a[2]],
             [b[0],1,b[2]],
             [c[0],1,c[2]]])
    z = np.linalg.det([[a[0],a[1],1],
             [b[0],b[1],1],
             [c[0],c[1],1]])
    magnitude = (x**2 + y**2 + z**2)**.5
    return (x/magnitude, y/magnitude, z/magnitude)

def poly_area(poly):
    if len(poly) < 3: # not a plane - no area
        return 0
    total = [0, 0, 0]
    N = len(poly)
    for i in range(N):
        vi1 = poly[i]
        vi2 = poly[(i+1) % N]
        prod = np.cross(vi1, vi2)
        total[0] += prod[0]
        total[1] += prod[1]
        total[2] += prod[2]
    result = np.dot(total, unit_normal(poly[0], poly[1], poly[2]))
    return abs(result/2)

########################################################
def AreaInPolyline(x,y):

    return 0.5*np.abs(np.dot(x,np.roll(y,1))-np.dot(y,np.roll(x,1))) 


def Calculate_Area(Swep,IfcGuid):
    global Area
    Area=[]
    if Swep.is_a('IfcCShapeProfileDef'):
        Height = round(Swep.Depth,2)
        Width = round(Swep.Width,2)
        Thickness = round(Swep.WallThickness,3)
        Girth = round(Swep.Girth,3)
        t_SurfaceArea = (Height+2*Width+2*Girth-4*Thickness)*Thickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcArbitraryClosedProfileDef'):
        OuterCurve = Swep.OuterCurve
        X_node =[]
        Y_node =[]
        t_Area=0
        if OuterCurve.is_a('IfcCompositeCurve'):
            Segment=OuterCurve.Segments
            for Curve in Segment:
                ParentCurve=Curve.ParentCurve
                if ParentCurve.is_a('IfcPolyline'):
                    for data in ParentCurve:
                        for node in data:

                            X_node.append(node.Coordinates[0])
                            Y_node.append(node.Coordinates[1])
                if ParentCurve.is_a('IfcTrimmedCurve'):
                    BasisCurve = ParentCurve.BasisCurve
                    if BasisCurve.is_a('IfcCircle'):
   
                        CenterX=BasisCurve.Position.Location.Coordinates[0]
                        CenterY=BasisCurve.Position.Location.Coordinates[1]
                        R = BasisCurve.Radius
                        Trim1=ParentCurve.Trim1
                        Trim2=ParentCurve.Trim2
                        if ParentCurve.MasterRepresentation =="PARAMETER":
                            if PlaneangleUint =="RADIAN":
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.radians(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.radians(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if ParentCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                                
                            else:
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if BasisCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(AngleStart),round(AngleStop),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(AngleStop),round(AngleStart),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                        elif ParentCurve.MasterRepresentation =="CARTESIAN":
                            x0=Trim1.Coordinates[0]
                            y0=Trim1.Coordinates[1]
                            X_node.append(x0)
                            Y_node.append(y0)
                            xEnd=Trim1.Coordinates[0]
                            yEnd=Trim1.Coordinates[1]
                            

                            AngleStart=math.acos((x0-CenterX)/R)
                            AngleStop=math.acos((xEnd-CenterX)/R)
                            if BasisCurve.SenseAgreement is True:
                                if AngleStart>AngleStop:
                                    step=10
                                else:
                                    step=-10

                                for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)
                            else:
                                if AngleStart>AngleStop:
                                    step=-10
                                else:
                                    step=10
                                for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)


        else:
            for data in OuterCurve:
                for node in data:

                    X_node.append(node.Coordinates[0])
                    Y_node.append(node.Coordinates[1])

        t_Area=0
        t_Area = AreaInPolyline(X_node,Y_node)
                                

        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001

        Area=[t_Area*pla,"SQUARE_METRE"]
                            

    elif Swep.is_a('IfcArbitraryOpenProfileDef'):
        print("BUGGGGGG!!!!!!!!!!!!!!IfcArbitraryOpenProfileDef")
        print(IfcGuid)

    elif Swep.is_a('IfcArbitraryProfileDefWithVoids'):
        OuterCurve = Swep.OuterCurve
        X_node =[]
        Y_node =[]
        t_Area=0
        if OuterCurve.is_a('IfcCompositeCurve'):
            Segment=OuterCurve.Segments
            for Curve in Segment:
                ParentCurve=Curve.ParentCurve
                if ParentCurve.is_a('IfcPolyline'):
                    for data in ParentCurve:
                        print(data)
                        for node in data:

                            X_node.append(node.Coordinates[0])
                            Y_node.append(node.Coordinates[1])
                if ParentCurve.is_a('IfcTrimmedCurve'):
                    BasisCurve = ParentCurve.BasisCurve
                    if BasisCurve.is_a('IfcCircle'):

                        CenterX=BasisCurve.Position.Location.Coordinates[0]
                        CenterY=BasisCurve.Position.Location.Coordinates[1]
                        R = BasisCurve.Radius
                        Trim1=ParentCurve.Trim1
                        Trim2=ParentCurve.Trim2
                        if ParentCurve.MasterRepresentation =="PARAMETER":
                            if PlaneangleUint =="RADIAN":
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.radians(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.radians(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if ParentCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                                
                            else:
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if BasisCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(AngleStart),round(AngleStop),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(AngleStop),round(AngleStart),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                        elif ParentCurve.MasterRepresentation =="CARTESIAN":
                            x0=Trim1.Coordinates[0]
                            y0=Trim1.Coordinates[1]
                            X_node.append(x0)
                            Y_node.append(y0)
                            xEnd=Trim1.Coordinates[0]
                            yEnd=Trim1.Coordinates[1]
                            

                            AngleStart=math.acos((x0-CenterX)/R)
                            AngleStop=math.acos((xEnd-CenterX)/R)
                            if BasisCurve.SenseAgreement is True:
                                if AngleStart>AngleStop:
                                    step=10
                                else:
                                    step=-10

                                for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)
                            else:
                                if AngleStart>AngleStop:
                                    step=-10
                                else:
                                    step=10
                                for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)


        else:
            for data in OuterCurve:
                for node in data:
                    X_node.append(node.Coordinates[0])
                    Y_node.append(node.Coordinates[1])

        
        t_Area = AreaInPolyline(X_node,Y_node)


        for Inner in Swep.InnerCurves:
            X_node =[]
            Y_node =[]
            InnerCurve=Inner
            if InnerCurve.is_a('IfcCompositeCurve'):
                Segment=InnerCurve.Segments
                for Curve in Segment:
                    ParentCurve=Curve.ParentCurve
                    if ParentCurve.is_a('IfcPolyline'):
                        for data in ParentCurve:
                            for node in data:

                                X_node.append(node.Coordinates[0])
                                Y_node.append(node.Coordinates[1])
                    if ParentCurve.is_a('IfcTrimmedCurve'):
                        BasisCurve = ParentCurve.BasisCurve
                        if BasisCurve.is_a('IfcCircle'):
                            CenterX=BasisCurve.Position.Location.Coordinates[0]
                            CenterY=BasisCurve.Position.Location.Coordinates[1]
                            R = BasisCurve.Radius
                            Trim1=ParentCurve.Trim1
                            Trim2=ParentCurve.Trim2
                            if ParentCurve.MasterRepresentation =="PARAMETER":
                                if PlaneangleUint =="RADIAN":
                                    AngleStart=Trim1[0][0]
                                    x0 = CenterX+(math.cos(math.radians(AngleStart)))*R
                                    y0 = CenterY+(math.cos(math.radians(AngleStart)))*R
                                    X_node.append(x0)
                                    Y_node.append(y0)
                                    AngleStop=Trim2[0][0]
                                    if ParentCurve.SenseAgreement is True:
                                        if AngleStart>AngleStop:
                                            step=10
                                        else:
                                            step=-10

                                        for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                            xx = CenterX+(math.cos(math.radians(angle)))*R
                                            yy = CenterY+(math.cos(math.radians(angle)))*R
                                            X_node.append(xx)
                                            Y_node.append(yy)
                                    else:
                                        if AngleStart>AngleStop:
                                            step=-10
                                        else:
                                            step=10
                                        for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                            xx = CenterX+(math.cos(math.radians(angle)))*R
                                            yy = CenterY+(math.cos(math.radians(angle)))*R
                                            X_node.append(xx)
                                            Y_node.append(yy)


                                
                                else:
                                    AngleStart=Trim1[0][0]
                                    x0 = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    y0 = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(x0)
                                    Y_node.append(y0)
                                    AngleStop=Trim2[0][0]
                                    if BasisCurve.SenseAgreement is True:
                                        if AngleStart>AngleStop:
                                            step=10
                                        else:
                                            step=-10

                                        for angle in range(round(AngleStart),round(AngleStop),step):
                                            xx = CenterX+(math.cos(math.degrees(angle)))*R
                                            yy = CenterY+(math.cos(math.degrees(angle)))*R
                                            X_node.append(xx)
                                            Y_node.append(yy)
                                    else:
                                        if AngleStart>AngleStop:
                                            step=-10
                                        else:
                                            step=10
                                        for angle in range(round(AngleStop),round(AngleStart),step):
                                            xx = CenterX+(math.cos(math.degrees(angle)))*R
                                            yy = CenterY+(math.cos(math.degrees(angle)))*R
                                            X_node.append(xx)
                                            Y_node.append(yy)


                            elif ParentCurve.MasterRepresentation =="CARTESIAN":
                                x0=Trim1.Coordinates[0]
                                y0=Trim1.Coordinates[1]
                                X_node.append(x0)
                                Y_node.append(y0)
                                xEnd=Trim1.Coordinates[0]
                                yEnd=Trim1.Coordinates[1]
                            

                                AngleStart=math.acos((x0-CenterX)/R)
                                AngleStop=math.acos((xEnd-CenterX)/R)
                                if BasisCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                        xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                        yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                        xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                        yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


            else:
                for data in InnerCurve:
                    for node in data:
                        X_node.append(node.Coordinates[0])
                        Y_node.append(node.Coordinates[1])


        t_Area = t_Area - AreaInPolyline(X_node,Y_node)
                        
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
  
        Area=[t_Area*pla,"SQUARE_METRE"]
                        

    elif Swep.is_a('IfcAsymmetricIShapeProfileDef'):
        OverallHeight = round(Swep.OverallDepth,2)
        OverallWidth = round(Swep.OverallWidth,2)
        WebThickness = round(Swep.WebThickness,3)
        FlangeThickness	 = round(Swep.FlangeThickness,3)
        TopFlangeWidth = round(Swep.TopFlangeWidth,2)
        t_SurfaceArea = OverallWidth*FlangeThickness + OverallHeight*WebThickness + TopFlangeWidth*FlangeThickness - 2*FlangeThickness*WebThickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]


    elif Swep.is_a('IfcCenterLineProfileDef'):
        Thickness = round(Swep.Thickness,3)
        curve = Swep.Curve
        X_node=[]
        Y_node=[]
        t_SurfaceArea=0
        t_Length=0
        if curve.is_a('IfcCompositeCurve'):
            Segment=curve.Segments
            for Curve in Segment:
                ParentCurve=Curve.ParentCurve
                if ParentCurve.is_a('IfcPolyline'):
                    for data in ParentCurve:
                        for node in data:

                            X_node.append(node.Coordinates[0])
                            Y_node.append(node.Coordinates[1])
                if ParentCurve.is_a('IfcTrimmedCurve'):
                    BasisCurve = ParentCurve.BasisCurve
                    if BasisCurve.is_a('IfcCircle'):
                        CenterX=BasisCurve.Position.Location.Coordinates[0]
                        CenterY=BasisCurve.Position.Location.Coordinates[1]
                        R = BasisCurve.Radius
                        Trim1=ParentCurve.Trim1
                        Trim2=ParentCurve.Trim2
                        if ParentCurve.MasterRepresentation =="PARAMETER":
                            if PlaneangleUint =="RADIAN":
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.radians(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.radians(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if ParentCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                        xx = CenterX+(math.cos(math.radians(angle)))*R
                                        yy = CenterY+(math.cos(math.radians(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                                
                            else:
                                AngleStart=Trim1[0][0]
                                x0 = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                y0 = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                X_node.append(x0)
                                Y_node.append(y0)
                                AngleStop=Trim2[0][0]
                                if BasisCurve.SenseAgreement is True:
                                    if AngleStart>AngleStop:
                                        step=10
                                    else:
                                        step=-10

                                    for angle in range(round(AngleStart),round(AngleStop),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)
                                else:
                                    if AngleStart>AngleStop:
                                        step=-10
                                    else:
                                        step=10
                                    for angle in range(round(AngleStop),round(AngleStart),step):
                                        xx = CenterX+(math.cos(math.degrees(angle)))*R
                                        yy = CenterY+(math.cos(math.degrees(angle)))*R
                                        X_node.append(xx)
                                        Y_node.append(yy)


                        elif ParentCurve.MasterRepresentation =="CARTESIAN":
                            x0=Trim1.Coordinates[0]
                            y0=Trim1.Coordinates[1]
                            X_node.append(x0)
                            Y_node.append(y0)
                            xEnd=Trim1.Coordinates[0]
                            yEnd=Trim1.Coordinates[1]
                            

                            AngleStart=math.acos((x0-CenterX)/R)
                            AngleStop=math.acos((xEnd-CenterX)/R)
                            if BasisCurve.SenseAgreement is True:
                                if AngleStart>AngleStop:
                                    step=10
                                else:
                                    step=-10

                                for angle in range(round(math.degrees(AngleStart)),round(math.degrees(AngleStop)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)
                            else:
                                if AngleStart>AngleStop:
                                    step=-10
                                else:
                                    step=10
                                for angle in range(round(math.degrees(AngleStop)),round(math.degrees(AngleStart)),step):
                                    xx = CenterX+(math.cos(math.degrees(AngleStart)))*R
                                    yy = CenterY+(math.cos(math.degrees(AngleStart)))*R
                                    X_node.append(xx)
                                    Y_node.append(yy)


        else:
            for data in curve:
                for node in data:

                    X_node.append(node.Coordinates[0])
                    Y_node.append(node.Coordinates[1])
        
        for i in range(len(X_node)):
            if i ==0:
                privous_x=X_node[i]
                privous_y=Y_node[i]
            else:
                l=round((((privous_x-X_node[i])**2)+((privous_y-Y_node[i])**2))**(0.5),2)
                t_Length = t_Length + l
                privous_x=X_node[i]
                privous_y=Y_node[i]
        t_SurfaceArea= t_length * Thickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

                        
    elif Swep.is_a('IfcCircleHollowProfileDef'):
        Thickness = round(Swep.WallThickness,3)
        Radius = round(Swep.Radius,3)
        t_SurfaceArea= 3.14159*(((Radius)**2)-((Radius-Thickness)**2))
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]
    elif Swep.is_a('IfcCircleProfileDef'):
        Radius = round(Swep.Radius,3)
        t_SurfaceArea= 3.14159*((Radius)**2)
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcEllipseProfileDef'):
        SemiAxis1 = round(Swep.SemiAxis1,3)
        SemiAxis2 = round(Swep.SemiAxis2,3)
        t_SurfaceArea= 3.14159*SemiAxis1*SemiAxis2
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]
    elif Swep.is_a('IfcIShapeProfileDef'):
        OverallHeight = round(Swep.OverallDepth,2)
        OverallWidth = round(Swep.OverallWidth,2)
        WebThickness = round(Swep.WebThickness,3)
        FlangeThickness	 = round(Swep.FlangeThickness,3)
                        
        t_SurfaceArea = 2*OverallWidth*FlangeThickness + OverallHeight*WebThickness - 2*FlangeThickness*WebThickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcLShapeProfileDef'):
        Height = round(Swep.Depth,2)
        Width = round(Swep.Width,2)
        if Width =="":
            Width = Height

        Thickness = round(Swep.Thickness,3)
        t_SurfaceArea = (Width+Height)*Thickness - Thickness*Thickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcRectangleHollowProfileDef'):
        XDim = round(Swep.XDim,2)
        YDim = round(Swep.YDim,2)
        Thickness = round(Swep.WallThickness,3)
        t_SurfaceArea = XDim*YDim - (YDim-2*Thickness)*(XDim-2*Thickness)
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcRectangleProfileDef'):
        XDim = round(Swep.XDim,2)
        YDim = round(Swep.YDim,2)
        t_SurfaceArea = XDim*YDim
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcRoundedRectangleProfileDef'):
        RoundingRadius = round(Swep.RoundingRadius,3)
        XDim = round(Swep.XDim,2)
        YDim = round(Swep.YDim,2)
        t_SurfaceArea = XDim*YDim - (((2*RoundingRadius)**2)-(3.14159*(RoundingRadius**2)))
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]


    elif Swep.is_a('IfcTShapeProfileDef'):
        Height = round(Swep.Depth,2)
        FlangeWidth = round(Swep.FlangeWidth,2)
        WebThickness = round(Swep.WebThickness,3)
        FlangeThickness = round(Swep.FlangeThickness,3)
        t_SurfaceArea = Height * WebThickness + FlangeWidth*FlangeThickness - FlangeThickness*WebThickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcTrapeziumProfileDef'):
        BottomXDim = round(Swep.BottomXDim,2)
        TopXDim = round(Swep.TopXDim,2)
        YDim = round(Swep.YDim,2)
        t_SurfaceArea = (BottomXDim+TopXDim)*YDim/2
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcUShapeProfileDef'):
        Height = round(Swep.Depth,3)
        FlangeWidth = round(Swep.FlangeWidth,3)
        WebThickness = round(Swep.WebThickness,3)
        FlangeThickness = round(Swep.FlangeThickness,3)
        t_SurfaceArea = Height * WebThickness + 2*FlangeWidth*FlangeThickness - 2*FlangeThickness*WebThickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcZShapeProfileDef'):
        Height = round(Swep.Depth.NominalValue,2)
        FlangeWidth = round(Swep.FlangeWidth,2)
        WebThickness = round(Swep.WebThickness,3)
        FlangeThickness = round(Swep.FlangeThickness,3)
        t_SurfaceArea = Height * WebThickness + 2*FlangeWidth*FlangeThickness - 2*FlangeThickness*WebThickness
        if LengthUint =="METRE":
            pla=1
        elif LengthUint=="CENTIMETRE":
            pla=0.0001
        elif LengthUint=="MILLIMETRE":
            pla=0.000001
        Area=[t_SurfaceArea*pla,"SQUARE_METRE"]

    elif Swep.is_a('IfcCompositeProfileDef'):
        print("IfcCompositeProfileDef")
        t_A = 0
        for Profile in Swep.Profiles:
            Calculate_Area(Swep,IfcGuid)
            t_A = t_A+Area
        Area=[t_A,"SQUARE_METRE"]

    elif Swep.is_a('IfcDerivedProfileDef'):
        ParentProfile = Swep.ParentProfile
        Calculate_Area(ParentProfile,IfcGuid)
    
    elif Swep.is_a('IfcParameterizedProfileDef'):
        print("BUGGGGGG!!!!!!!!!!!!!!IfcParameterizedProfileDef")
        print(IfcGuid)
        print(Swep)

    else:
        print("BUGGGGGG!!!!!!!!!!!!!!Area")
        print(IfcGuid)
        print(Swep)
    
    


    
       


def QTOfromIFC():
    ####address Of IfC file###
    ifc_file = ifcopenshell.open('D:/IFC reader/IFC Work (main)-code/Code/test9- OTOpy OPTm - tekla - shape in IFC2 - scenario for stock - change number of material and initial - change case study/JahanAra.ifc')
    #ifc_file = ifcopenshell.open('D:/IFC reader/CheckPlate/PL15.ifc')
    #
    ##########################
    #########moshakhas kardane vahed ha
    global AreaUint,VolumeUint,LengthUint,PlaneangleUint,MassUint,TimeUint,FrequencyUint,Area,product_information
    unit_of_file = ifc_file.by_type('IfcUnitAssignment')
    for item in unit_of_file:
        for unit in item.Units:
             if unit.UnitType=="LENGTHUNIT":
                if unit.Prefix is None:
                    LengthUint=unit.Name
                else:
                    LengthUint=unit.Prefix + unit.Name  
             if unit.UnitType=="AREAUNIT":
                AreaUint=unit.Name
             if unit.UnitType=="VOLUMEUNIT":
                VolumeUint=unit.Name
             if unit.UnitType=="PLANEANGLEUNIT":
                PlaneangleUint=unit.Name
             if unit.UnitType=="MASSUNIT":
                MassUint=unit.Name
             if unit.UnitType=="TIMEUNIT":
                TimeUint=unit.Name
             if unit.UnitType=="FREQUENCYUNIT":
                FrequencyUint=unit.Name
    products = ifc_file.by_type('IfcProduct')
    #### products is a list, baraye namayesh ozve 3 vome list az dastor zir mirim####
    #print(products[2].is_a())  
    ###########################
    ###### baraye namayesh tamame ifcProduct haye mojod to file###### agar .is_a() nazarim matne mojod to file ifc asli ro miare

    ####list item eleman hai ke morde barasi gharar migirad######
    selected_item = ['IfcWallStandardCase','IfcWall','IfcColumn','IfcSlab','IfcBeam','IfcPlate','IfcMember']
    #############################


    
    
    
###############################################################################
    product_information=[]
    list_Profile=[]
    for product in products:
        MatName =[]
        volume =[] 
        Length=[]
        Height=[]
        if product.is_a() in selected_item:
################## IFCWALL ###############
            if product.is_a('IfcWallStandardCase') or product.is_a('IfcWall') or product.is_a('IfcSlab'):
                StringProduct = str(product)
                Temp_string = StringProduct.split('=')
                LineNumberProduct = Temp_string[0]
                IfcGuid = product.GlobalId
                Element_Name= product.Name + "'   " "which in IFC Identify with '" + product.is_a() + "'"
                Profile = "NoProfile"
                geometry = product.ObjectPlacement.RelativePlacement 
                X=geometry.Location.Coordinates[0]
                Y=geometry.Location.Coordinates[1]
                Z=geometry.Location.Coordinates[2]
                DirX=round(geometry.RefDirection.DirectionRatios[0],3)
                DirY=round(geometry.RefDirection.DirectionRatios[1],3)
                DirZ=round(geometry.RefDirection.DirectionRatios[2],3)
                if DirX==0 and DirY==0:
                   orientation = "Z"
                elif DirX==0 and DirZ==0:
                   orientation = "Y"
                elif DirZ==0 and DirY==0:
                   orientation = "X"
                elif DirX==0:
                   orientation = "Y-Z"
                elif DirY==0:
                   orientation = "X-Z"
                elif DirZ==0:
                   orientation = "X-Y"
                else:
                   orientation = "X-Y-Z"

                shape = product.Representation.Representations[0].Items[0]
                if shape.is_a('IfcBooleanClippingResult') :
                    Operator = shape.Operator
                    FirstOperand=shape.FirstOperand
                    SecondOperand=shape.SecondOperand
                    findArea = False
                    name = shape.FirstOperand
                    while findArea == False:
                        if name.is_a('IfcExtrudedAreaSolid'):
                            Length = [name.Depth,LengthUint]
                            Swep=name.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                            findArea = True
                        else:
                            name = name.FirstOperand

                elif shape.is_a('IfcBooleanResult'):
                    Operator = shape.Operator
                    FirstOperand=shape.FirstOperand
                    SecondOperand=shape.SecondOperand
                    if Operator == "DIFFERENCE":
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Length = [name.Depth,LengthUint]
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand
                    elif Operator == "UNION":
                        if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                            Length = [FirstOperand.Depth,LengthUint]
                            Swep=FirstOperand.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                        elif FirstOperand.is_('IfcBooleanResult'):
                            if FirstOperand.Operator == "DIFFERENCE":
                                if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                    Length = [FirstOperand.FirstOperand.Depth,LengthUint]
                                    Swep=FirstOperand.FirstOperand.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    A1=Area[0]
                        if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                            Length = [SecondOperand.Depth,LengthUint]
                            Swep=SecondOperand.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                        elif SecondOperand.is_a('IfcBooleanResult'):
                            if SecondOperand.Operator == "DIFFERENCE":
                                if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                    Length = [SecondOperand.FirstOperand.Depth,LengthUint]
                                    Swep=SecondOperand.FirstOperand.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    A1=Area[0]
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                        print(FirstOperand.is_a())
                        print(IfcGuid)
                elif shape.is_a('IfcFacetedBrep'):
                    t_OuterandInnerArea=0
                    t_Surface_Area=0
                    polyOuter=[]
                    for Face in shape.Outer.CfsFaces:
                        if len(Face.Bounds)==2:
                            polyFace=[]
                            polyOuter=[]
                            sum_len=0
                            for bound in Face.Bounds:
                                if bound.is_a()=="IfcFaceBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyFace.append([x,y,z])
  
                                if bound.is_a()=="IfcFaceOuterBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])
                           
                            t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                            i=0

                            for node in polyOuter:
                                
                                i=i+1
                                if i==1:
                                    x1=node[0]
                                    y1=node[1]
                                    z1=node[2]
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]
                                else:
                                    lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                    sum_len=sum_len + lenNodes
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]

                                if i==len(polyOuter):
                                    lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                    sum_len=sum_len + lenNodes 
                            i=0

                            for node in polyFace:
                                
                                i=i+1
                                if i==1:
                                    x1=node[0]
                                    y1=node[1]
                                    z1=node[2]
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]
                                else:
                                    lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                    sum_len=sum_len + lenNodes
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]

                                if i==len(polyOuter):
                                    lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                    sum_len=sum_len + lenNodes 


                            EnviSurface = sum_len
                                

                        else:
                            polyOuter=[]
                            for bound in Face.Bounds:
                                if bound.is_a()=="IfcFaceBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])

                                    t_Surface_Area=poly_area(polyOuter)

                                elif bound.is_a()=="IfcFaceOuterBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])

                                    t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                    if LengthUint =="METRE":
                        pav=1
                        pla=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                        pla=0.0001
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001
                        pla=0.000001
                    AreaOuterandInnerSurface =t_OuterandInnerArea
                    SurfaceArea = t_Surface_Area
                    Area = [SurfaceArea*pla , "CUBIC_METER"]
                    Length=[AreaOuterandInnerSurface/EnviSurface,LengthUint]

                    
                elif shape.is_a('IfcExtrudedAreaSolid'):
                    Length = [shape.Depth,LengthUint]
                    Swep = shape.SweptArea
                    Calculate_Area(Swep,IfcGuid)
                else:
                    print("BUGGGGGG!!!!!!!!!!!!!!")
                    print(shape.is_a())
                    print(IfcGuid)


                if LengthUint =="METRE":
                    pav=1
                elif LengthUint=="CENTIMETRE":
                    pav=0.01
                elif LengthUint=="MILLIMETRE":
                    pav=0.001

                
                for Assign in product.HasAssociations:
                    for layer in Assign.RelatingMaterial.ForLayerSet.MaterialLayers:
                        Volume=[]
                        MatName=[]
                        MaterialName = Assign.RelatingMaterial.Name
                        MatName=[1,layer.Material.Name,round(layer.LayerThickness,2),LengthUint]
                        Volume = [Area[0]*MatName[2]*pav,"CUBIC_METRE"]
                        product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,Area,Volume,LineNumberProduct]) 
                        
                        if len(list_Profile)==0:
                            list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                        else:
                            exist=0
                            for item in list_Profile:
                                if Profile==item[1] and MaterialName==item[2]:
                                    exist = 1
                            if exist == 0:
                                list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    

###############################################################################
            if product.is_a('IfcPlate'):

                StringProduct = str(product)
                Temp_string = StringProduct.split('=')
                LineNumberProduct = Temp_string[0]
                IfcGuid = product.GlobalId
                Element_Name= product.Name + "'   " "which in IFC Identify with '" + product.is_a() + "'"
                
                geometry = product.ObjectPlacement.RelativePlacement 
                X=geometry.Location.Coordinates[0]
                Y=geometry.Location.Coordinates[1]
                Z=geometry.Location.Coordinates[2]
                DirX=round(geometry.RefDirection.DirectionRatios[0],3)
                DirY=round(geometry.RefDirection.DirectionRatios[1],3)
                DirZ=round(geometry.RefDirection.DirectionRatios[2],3)
                if DirX==0 and DirY==0:
                   orientation = "Z"
                elif DirX==0 and DirZ==0:
                   orientation = "Y"
                elif DirZ==0 and DirY==0:
                   orientation = "X"
                elif DirX==0:
                   orientation = "Y-Z"
                elif DirY==0:
                   orientation = "X-Z"
                elif DirZ==0:
                   orientation = "X-Y"
                else:
                   orientation = "X-Y-Z"

                shape = product.Representation.Representations[0].Items[0]
                if shape.is_a('IfcBooleanClippingResult'):
                    Operator = shape.Operator
                    FirstOperand=shape.FirstOperand
                    SecondOperand=shape.SecondOperand
                    findArea = False
                    name = shape.FirstOperand
                    while findArea == False:
                        if name.is_a('IfcExtrudedAreaSolid'):
                            Height = [name.Depth,LengthUint]
                            Profile = "PL"+str(round(Height[0]))
                            Swep=name.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                            findArea = True
                        else:
                            name = name.FirstOperand

                elif shape.is_a('IfcBooleanResult'):
                    Operator = shape.Operator
                    FirstOperand=shape.FirstOperand
                    SecondOperand=shape.SecondOperand
                    if Operator == "DIFFERENCE":
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Height = [name.Depth,LengthUint]
                                Profile = "PL"+str(round(Height[0]))
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand
                    elif Operator == "UNION":
                        if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                            Height = [FirstOperand.Depth,LengthUint]
                            Profile = "PL"+str(round(Height[0]))
                            Swep=FirstOperand.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                        elif FirstOperand.is_a('IfcBooleanResult'):
                            if FirstOperand.Operator == "DIFFERENCE":
                                if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                    Height = [FirstOperand.FirstOperand.Depth,LengthUint]
                                    Profile = "PL"+str(round(Height[0]))
                                    Swep=FirstOperand.FirstOperand.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    A1=Area[0]
                        if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                            Height = [SecondOperand.Depth,LengthUint]
                            Profile = "PL"+str(round(Height[0]))
                            Swep=SecondOperand.SweptArea
                            Calculate_Area(Swep,IfcGuid)
                        elif SecondOperand.is_a('IfcBooleanResult'):
                            if SecondOperand.Operator == "DIFFERENCE":
                                if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                    Height = [SecondOperand.FirstOperand.Depth,LengthUint]
                                    Profile = "PL"+str(round(Height[0]))
                                    Swep=SecondOperand.FirstOperand.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    A1=Area[0]
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                        print(FirstOperand.is_a())
                        print(IfcGuid)
                elif shape.is_a('IfcExtrudedAreaSolid'):
                    Height = [shape.Depth,LengthUint]
                    Profile = "PL"+str(round(Height[0]))
                    Swep = shape.SweptArea
                    Calculate_Area(Swep,IfcGuid)
                elif shape.is_a('IfcFacetedBrep'):
                    t_OuterandInnerArea=0
                    t_Surface_Area=0
                    polyOuter=[]
                    for Face in shape.Outer.CfsFaces:
                        if len(Face.Bounds)==2:
                            polyFace=[]
                            polyOuter=[]
                            sum_len=0
                            for bound in Face.Bounds:
                                if bound.is_a()=="IfcFaceBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyFace.append([x,y,z])
  
                                if bound.is_a()=="IfcFaceOuterBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])
                           
                            t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                            i=0

                            for node in polyOuter:
                                
                                i=i+1
                                if i==1:
                                    x1=node[0]
                                    y1=node[1]
                                    z1=node[2]
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]
                                else:
                                    lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                    sum_len=sum_len + lenNodes
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]

                                if i==len(polyOuter):
                                    lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                    sum_len=sum_len + lenNodes 
                            i=0

                            for node in polyFace:
                                
                                i=i+1
                                if i==1:
                                    x1=node[0]
                                    y1=node[1]
                                    z1=node[2]
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]
                                else:
                                    lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                    sum_len=sum_len + lenNodes
                                    pri_x=node[0]
                                    pri_y=node[1]
                                    pri_z=node[2]

                                if i==len(polyOuter):
                                    lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                    sum_len=sum_len + lenNodes 


                            EnviSurface = sum_len
                                

                        else:
                            polyOuter=[]
                            for bound in Face.Bounds:
                                if bound.is_a()=="IfcFaceBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])

                                    t_Surface_Area=poly_area(polyOuter)

                                elif bound.is_a()=="IfcFaceOuterBound":
                                    for node in bound.Bound.Polygon:
                                        x=node.Coordinates[0]
                                        y=node.Coordinates[1]
                                        z=node.Coordinates[2]
                                        polyOuter.append([x,y,z])

                                    t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                    if LengthUint =="METRE":
                        pav=1
                        pla=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                        pla=0.0001
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001
                        pla=0.000001
                    AreaOuterandInnerSurface =t_OuterandInnerArea
                    SurfaceArea = t_Surface_Area
                    Area = [SurfaceArea*pla , "CUBIC_METER"]
                    Height=[AreaOuterandInnerSurface/EnviSurface,LengthUint]
                    Profile = "PL"+str(Height[0])
                else:
                    print("BUGGGGGG!!!!!!!!!!!!!!")
                    print(shape.is_a())
                    print(IfcGuid)


                for Assign in product.HasAssociations:
                    MaterialName = Assign.RelatingMaterial.Name
                    MatName=[2,Assign.RelatingMaterial.Name,0,LengthUint]
                
                
                if LengthUint =="METRE":
                    pav=1
                elif LengthUint=="CENTIMETRE":
                    pav=0.01
                elif LengthUint=="MILLIMETRE":
                    pav=0.001
                Volume = [Area[0]*Height[0]*pav,"CUBIC_METRE"]
                product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[0,"METRE"],Area,Volume,LineNumberProduct])

                if len(list_Profile)==0:
                    list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                else:
                    exist=0
                    for item in list_Profile:
                        if Profile==item[1] and MaterialName==item[2]:
                            exist = 1
                    if exist == 0:
                        list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    

##################################


###################################################################
            if product.is_a('IfcMember'):

                StringProduct = str(product)
                Temp_string = StringProduct.split('=')
                LineNumberProduct = Temp_string[0]
                Element_Name= product.Name + "'   " "which in IFC Identify with '" + product.is_a() + "'"
                IfcGuid = product.GlobalId
                Element_Name= product.Name + "'   " "which in IFC Identify with '" + product.is_a() + "'"
                Profile = product.ObjectType
                geometry = product.ObjectPlacement.RelativePlacement 
                X=geometry.Location.Coordinates[0]
                Y=geometry.Location.Coordinates[1]
                Z=geometry.Location.Coordinates[2]
                DirX=round(geometry.RefDirection.DirectionRatios[0],3)
                DirY=round(geometry.RefDirection.DirectionRatios[1],3)
                DirZ=round(geometry.RefDirection.DirectionRatios[2],3)
                if DirX==0 and DirY==0:
                   orientation = "Z"
                elif DirX==0 and DirZ==0:
                   orientation = "Y"
                elif DirZ==0 and DirY==0:
                   orientation = "X"
                elif DirX==0:
                   orientation = "Y-Z"
                elif DirY==0:
                   orientation = "X-Z"
                elif DirZ==0:
                   orientation = "X-Y"
                else:
                   orientation = "X-Y-Z"

                if Profile[0:2]=="PL": 
                    i=0
                    profDone = False
                    while profDone == False:
                        if Profile[i]=="*":
                            Profile = Profile[0:i]
                            profDone = True
                        else:
                            i = i+1
                    shape = product.Representation.Representations[0].Items[0]
                    if shape.is_a('IfcBooleanClippingResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        #print(shape.FirstOperand.FirstOperand)
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Height = [name.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand

                    elif shape.is_a('IfcBooleanResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        if Operator == "DIFFERENCE":
                            findArea = False
                            name = shape.FirstOperand
                            while findArea == False:
                                if name.is_a('IfcExtrudedAreaSolid'):
                                    Height = [name.Depth,LengthUint]
                                    #Profile = "PL"+str(round(Height[0]))
                                    Swep=name.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    findArea = True
                                else:
                                    name = name.FirstOperand
                        elif Operator == "UNION":
                            if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                Height = [FirstOperand.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=FirstOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif FirstOperand.is_a('IfcBooleanResult'):
                                if FirstOperand.Operator == "DIFFERENCE":
                                    if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Height = [FirstOperand.FirstOperand.Depth,LengthUint]
                                        #Profile = "PL"+str(round(Height[0]))
                                        Swep=FirstOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                            if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                                Height = [SecondOperand.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=SecondOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif SecondOperand.is_a('IfcBooleanResult'):
                                if SecondOperand.Operator == "DIFFERENCE":
                                    if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Height = [SecondOperand.FirstOperand.Depth,LengthUint]
                                        #Profile = "PL"+str(round(Height[0]))
                                        Swep=SecondOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                        else:
                            print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                            print(FirstOperand.is_a())
                            print(IfcGuid)

                    elif shape.is_a('IfcFacetedBrep'):
                        t_OuterandInnerArea=0
                        t_Surface_Area=0
                        polyOuter=[]
                        for Face in shape.Outer.CfsFaces:
                            if len(Face.Bounds)==2:
                                polyFace=[]
                                polyOuter=[]
                                sum_len=0
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyFace.append([x,y,z])
  
                                    if bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])
                           
                                t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                                i=0

                                for node in polyOuter:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 
                                i=0

                                for node in polyFace:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 


                                EnviSurface = sum_len
                                

                            else:
                                polyOuter=[]
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_Surface_Area=poly_area(polyOuter)

                                    elif bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                        if LengthUint =="METRE":
                            pav=1
                            pla=1
                        elif LengthUint=="CENTIMETRE":
                            pav=0.01
                            pla=0.0001
                        elif LengthUint=="MILLIMETRE":
                            pav=0.001
                            pla=0.000001
                        AreaOuterandInnerSurface =t_OuterandInnerArea
                        SurfaceArea = t_Surface_Area
                        Area = [SurfaceArea*pla , "CUBIC_METER"]
                        Height=[AreaOuterandInnerSurface/EnviSurface,LengthUint]
                        #Profile = "PL"+str(Height[0])
                    elif shape.is_a('IfcExtrudedAreaSolid'):
                        Height = [shape.Depth,LengthUint]
                        #Profile = "PL"+str(round(Height[0]))
                        Swep = shape.SweptArea
                        Calculate_Area(Swep,IfcGuid)
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!")
                        print(shape.is_a())
                        print(IfcGuid)


                    for Assign in product.HasAssociations:
                        MaterialName = Assign.RelatingMaterial.Name
                        MatName=[3,Assign.RelatingMaterial.Name,0,LengthUint]
                
                    if LengthUint =="METRE":
                        pav=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001
                    Volume = [Area[0]*Height[0]*pav,"CUBIC_METRE"]
                    product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[0,"METRE"],Area,Volume,LineNumberProduct])
                    if len(list_Profile)==0:
                        list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    else:
                        exist=0
                        for item in list_Profile:
                            if Profile==item[1] and MaterialName==item[2]:
                                exist = 1
                        if exist == 0:
                            list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    
                else:
                    shape = product.Representation.Representations[0].Items[0]
                    if shape.is_a('IfcBooleanClippingResult') :
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        #print(shape.FirstOperand.FirstOperand)
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Length = [name.Depth,LengthUint]
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand

                    elif shape.is_a('IfcBooleanResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        if Operator == "DIFFERENCE":
                            findArea = False
                            name = shape.FirstOperand
                            while findArea == False:
                                if name.is_a('IfcExtrudedAreaSolid'):
                                    Length = [name.Depth,LengthUint]
                                    Swep=name.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    findArea = True
                                else:
                                    name = name.FirstOperand

                        elif Operator == "UNION":
                            if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                Length = [FirstOperand.Depth,LengthUint]
                                Swep=FirstOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif FirstOperand.is_('IfcBooleanResult'):
                                if FirstOperand.Operator == "DIFFERENCE":
                                    if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Length = [FirstOperand.FirstOperand.Depth,LengthUint]
                                        Swep=FirstOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                            if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                                Length = [SecondOperand.Depth,LengthUint]
                                Swep=SecondOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif SecondOperand.is_a('IfcBooleanResult'):
                                if SecondOperand.Operator == "DIFFERENCE":
                                    if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Length = [SecondOperand.FirstOperand.Depth,LengthUint]
                                        Swep=SecondOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                        else:
                            print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                            print(FirstOperand.is_a())
                            print(IfcGuid)
                    elif shape.is_a('IfcFacetedBrep'):
                        t_OuterandInnerArea=0
                        t_Surface_Area=0
                        polyOuter=[]
                        for Face in shape.Outer.CfsFaces:
                            if len(Face.Bounds)==2:
                                polyFace=[]
                                polyOuter=[]
                                sum_len=0
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyFace.append([x,y,z])
  
                                    if bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])
                           
                                t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                                i=0

                                for node in polyOuter:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 
                                i=0

                                for node in polyFace:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 


                                EnviSurface = sum_len
                                

                            else:
                                polyOuter=[]
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_Surface_Area=poly_area(polyOuter)

                                    elif bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                        if LengthUint =="METRE":
                            pav=1
                            pla=1
                        elif LengthUint=="CENTIMETRE":
                            pav=0.01
                            pla=0.0001
                        elif LengthUint=="MILLIMETRE":
                            pav=0.001
                            pla=0.000001

                        if t_Surface_Area != 0:
                            AreaOuterandInnerSurface =t_OuterandInnerArea
                            SurfaceArea = t_Surface_Area
                            Area = [SurfaceArea*pla , "CUBIC_METER"]
                            Length=[AreaOuterandInnerSurface/EnviSurface,LengthUint]
                        else:
                            Area = [0*pla , "CUBIC_METER"]
                            Length=[0,LengthUint]
                    
                    elif shape.is_a('IfcExtrudedAreaSolid'):
                        Length = [shape.Depth,LengthUint]
                        Swep = shape.SweptArea
                        Calculate_Area(Swep,IfcGuid)
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!")
                        print(shape.is_a())
                        print(IfcGuid)


                    for Assign in product.HasAssociations:
                        MaterialName = Assign.RelatingMaterial.Name
                        MatName=[3,Assign.RelatingMaterial.Name,0,LengthUint]
                
                    if LengthUint =="METRE":
                        pav=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001
                    Volume = [Area[0]*Length[0]*pav,"CUBIC_METRE"]
                    product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[Length[0]*pav,"METRE"],Area,Volume,LineNumberProduct])
                    
                    if len(list_Profile)==0:
                        list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    else:
                        exist=0
                        for item in list_Profile:
                            if Profile==item[1] and MaterialName==item[2]:
                                exist = 1
                        if exist == 0:
                            list_Profile.append([len(list_Profile)+1,Profile,MaterialName])

##################################


            if product.is_a('IfcColumn') or product.is_a('IfcBeam'):

                StringProduct = str(product)
                Temp_string = StringProduct.split('=')
                LineNumberProduct = Temp_string[0]
                IfcGuid = product.GlobalId
                Element_Name= product.Name + "'   " "which in IFC Identify with '" + product.is_a() + "'"
                Profile = product.ObjectType
                geometry = product.ObjectPlacement.RelativePlacement 
                X=geometry.Location.Coordinates[0]
                Y=geometry.Location.Coordinates[1]
                Z=geometry.Location.Coordinates[2]
                DirX=round(geometry.RefDirection.DirectionRatios[0],3)
                DirY=round(geometry.RefDirection.DirectionRatios[1],3)
                DirZ=round(geometry.RefDirection.DirectionRatios[2],3)
                if DirX==0 and DirY==0:
                   orientation = "Z"
                elif DirX==0 and DirZ==0:
                   orientation = "Y"
                elif DirZ==0 and DirY==0:
                   orientation = "X"
                elif DirX==0:
                   orientation = "Y-Z"
                elif DirY==0:
                   orientation = "X-Z"
                elif DirZ==0:
                   orientation = "X-Y"
                else:
                   orientation = "X-Y-Z"
                shape = product.Representation.Representations[0].Items[0]
                if Profile[0:2]=="PL": 
                    i=0
                    profDone = False
                    while profDone == False:
                        if Profile[i]=="*":
                            Profile = Profile[0:i]
                            profDone = True
                        else:
                            i = i+1
                    shape = product.Representation.Representations[0].Items[0]
                    if shape.is_a('IfcBooleanClippingResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        #print(shape.FirstOperand.FirstOperand)
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Height = [name.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand

                    elif shape.is_a('IfcBooleanResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        if Operator == "DIFFERENCE":
                            findArea = False
                            name = shape.FirstOperand
                            while findArea == False:
                                if name.is_a('IfcExtrudedAreaSolid'):
                                    Height = [name.Depth,LengthUint]
                                    #Profile = "PL"+str(round(Height[0]))
                                    Swep=name.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    findArea = True
                                else:
                                    name = name.FirstOperand
                        elif Operator == "UNION":
                            if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                Height = [FirstOperand.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=FirstOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif FirstOperand.is_a('IfcBooleanResult'):
                                if FirstOperand.Operator == "DIFFERENCE":
                                    if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Height = [FirstOperand.FirstOperand.Depth,LengthUint]
                                        #Profile = "PL"+str(round(Height[0]))
                                        Swep=FirstOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                            if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                                Height = [SecondOperand.Depth,LengthUint]
                                #Profile = "PL"+str(round(Height[0]))
                                Swep=SecondOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif SecondOperand.is_a('IfcBooleanResult'):
                                if SecondOperand.Operator == "DIFFERENCE":
                                    if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Height = [SecondOperand.FirstOperand.Depth,LengthUint]
                                        #Profile = "PL"+str(round(Height[0]))
                                        Swep=SecondOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                        else:
                            print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                            print(FirstOperand.is_a())
                            print(IfcGuid)

                    elif shape.is_a('IfcFacetedBrep'):
                        t_OuterandInnerArea=0
                        t_Surface_Area=0
                        polyOuter=[]
                        for Face in shape.Outer.CfsFaces:
                            if len(Face.Bounds)==2:
                                polyFace=[]
                                polyOuter=[]
                                sum_len=0
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyFace.append([x,y,z])
  
                                    if bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])
                           
                                t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                                i=0

                                for node in polyOuter:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 
                                i=0

                                for node in polyFace:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 


                                EnviSurface = sum_len
                                

                            else:
                                polyOuter=[]
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_Surface_Area=poly_area(polyOuter)

                                    elif bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                        if LengthUint =="METRE":
                            pav=1
                            pla=1
                        elif LengthUint=="CENTIMETRE":
                            pav=0.01
                            pla=0.0001
                        elif LengthUint=="MILLIMETRE":
                            pav=0.001
                            pla=0.000001
                        AreaOuterandInnerSurface =t_OuterandInnerArea
                        SurfaceArea = t_Surface_Area
                        Area = [SurfaceArea*pla , "CUBIC_METER"]  
                        if EnviSurface!=0:
                            Height=[AreaOuterandInnerSurface/EnviSurface,LengthUint]
                        else:
                            Height=[0,LengthUint]

                        
                        #Profile = "PL"+str(Height[0])
                    elif shape.is_a('IfcExtrudedAreaSolid'):
                        Height = [shape.Depth,LengthUint]
                        #Profile = "PL"+str(round(Height[0]))
                        Swep = shape.SweptArea
                        Calculate_Area(Swep,IfcGuid)
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!")
                        print(shape.is_a())
                        print(IfcGuid)


                    for Assign in product.HasAssociations:
                        MaterialName = Assign.RelatingMaterial.Name
                        MatName=[3,Assign.RelatingMaterial.Name,0,LengthUint]
                
                    if LengthUint =="METRE":
                        pav=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001

                    Volume = [Area[0]*Height[0]*pav,"CUBIC_METRE"]
                    product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[0,"METRE"],Area,Volume,LineNumberProduct])
                    

                    
                    #Volume = [Area[0]*Height[0]*pav,"CUBIC_METRE"]
                    #product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[0,"METRE"],Area,Volume,LineNumberProduct])
                    if len(list_Profile)==0:
                        list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    else:
                        exist=0
                        for item in list_Profile:
                            if Profile==item[1] and MaterialName==item[2]:
                                exist = 1
                        if exist == 0:
                            list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    
                else:


                    if shape.is_a('IfcBooleanClippingResult') :
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        #print(shape.FirstOperand.FirstOperand)
                        findArea = False
                        name = shape.FirstOperand
                        while findArea == False:
                            if name.is_a('IfcExtrudedAreaSolid'):
                                Length = [name.Depth,LengthUint]
                                Swep=name.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                                findArea = True
                            else:
                                name = name.FirstOperand

                    elif shape.is_a('IfcBooleanResult'):
                        Operator = shape.Operator
                        FirstOperand=shape.FirstOperand
                        SecondOperand=shape.SecondOperand
                        if Operator == "DIFFERENCE":
                            findArea = False
                            name = shape.FirstOperand
                            while findArea == False:
                                if name.is_a('IfcExtrudedAreaSolid'):
                                    Length = [name.Depth,LengthUint]
                                    Swep=name.SweptArea
                                    Calculate_Area(Swep,IfcGuid)
                                    findArea = True
                                else:
                                    name = name.FirstOperand
                        elif Operator == "UNION":
                            if FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                Length = [FirstOperand.Depth,LengthUint]
                                Swep=FirstOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif FirstOperand.is_a('IfcBooleanResult'):
                                if FirstOperand.Operator == "DIFFERENCE":
                                    if FirstOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Length = [FirstOperand.FirstOperand.Depth,LengthUint]
                                        Swep=FirstOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                            if SecondOperand.is_a('IfcExtrudedAreaSolid'):
                                Length = [SecondOperand.Depth,LengthUint]
                                Swep=SecondOperand.SweptArea
                                Calculate_Area(Swep,IfcGuid)
                            elif SecondOperand.is_a('IfcBooleanResult'):
                                if SecondOperand.Operator == "DIFFERENCE":
                                    if SecondOperand.FirstOperand.is_a('IfcExtrudedAreaSolid'):
                                        Length = [SecondOperand.FirstOperand.Depth,LengthUint]
                                        Swep=SecondOperand.FirstOperand.SweptArea
                                        Calculate_Area(Swep,IfcGuid)
                                        A1=Area[0]
                        else:
                            print("BUGGGGGG!!!!!!!!!!!!!!IfcBooleanResult")
                            print(FirstOperand.is_a())
                            print(IfcGuid)
                    elif shape.is_a('IfcFacetedBrep'):
                        t_OuterandInnerArea=0
                        t_Surface_Area=0
                        EnviSurface=0
                        sum_len=0
                        lenNodes=0
                        polyOuter=[]
                        for Face in shape.Outer.CfsFaces:
                            if len(Face.Bounds)==2:
                                polyFace=[]
                                polyOuter=[]
                                sum_len=0
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyFace.append([x,y,z])
  
                                    if bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])
                           
                                t_Surface_Area =poly_area(polyOuter)-poly_area(polyFace)
                                i=0
                            
                                for node in polyOuter:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 
                                i=0

                                for node in polyFace:
                                
                                    i=i+1
                                    if i==1:
                                        x1=node[0]
                                        y1=node[1]
                                        z1=node[2]
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]
                                    else:
                                        lenNodes=(((node[0]-pri_x)**2)+((node[1]-pri_y)**2)+((node[2]-pri_z)**2))**0.5
                                        sum_len=sum_len + lenNodes
                                        pri_x=node[0]
                                        pri_y=node[1]
                                        pri_z=node[2]

                                    if i==len(polyOuter):
                                        lenNodes=(((node[0]-x1)**2)+((node[1]-y1)**2)+((node[2]-z1)**2))**0.5
                                        sum_len=sum_len + lenNodes 


                                EnviSurface = sum_len
                                

                            else:
                                polyOuter=[]
                                for bound in Face.Bounds:
                                    if bound.is_a()=="IfcFaceBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_Surface_Area=poly_area(polyOuter)

                                    elif bound.is_a()=="IfcFaceOuterBound":
                                        for node in bound.Bound.Polygon:
                                            x=node.Coordinates[0]
                                            y=node.Coordinates[1]
                                            z=node.Coordinates[2]
                                            polyOuter.append([x,y,z])

                                        t_OuterandInnerArea= t_OuterandInnerArea + poly_area(polyOuter) 

                        if LengthUint =="METRE":
                            pav=1
                            pla=1
                        elif LengthUint=="CENTIMETRE":
                            pav=0.01
                            pla=0.0001
                        elif LengthUint=="MILLIMETRE":
                            pav=0.001
                            pla=0.000001
                        if t_Surface_Area != 0:
                            AreaOuterandInnerSurface =t_OuterandInnerArea
                            SurfaceArea = t_Surface_Area
                            Area = [SurfaceArea*pla , "CUBIC_METER"]
                            Length=[AreaOuterandInnerSurface/EnviSurface,LengthUint]
                        else:
                            Area = [0*pla , "CUBIC_METER"]
                            Length=[0,LengthUint]
                    elif shape.is_a('IfcExtrudedAreaSolid'):
                        Length = [shape.Depth,LengthUint]
                        Swep = shape.SweptArea
                        Calculate_Area(Swep,IfcGuid)
                    else:
                        print("BUGGGGGG!!!!!!!!!!!!!!")
                        print(shape.is_a())
                        print(IfcGuid)



                    for Assign in product.HasAssociations:
                        MaterialName = Assign.RelatingMaterial.Name
                        MatName=[4,Assign.RelatingMaterial.Name,0,LengthUint]
                
                    if LengthUint =="METRE":
                        pav=1
                    elif LengthUint=="CENTIMETRE":
                        pav=0.01
                    elif LengthUint=="MILLIMETRE":
                        pav=0.001
                    Volume = [Area[0]*Length[0]*pav,"CUBIC_METRE"]
                    product_information.append([Element_Name,IfcGuid,Profile,X,Y,Z,orientation,MatName,[Length[0]*pav,"METRE"],Area,Volume,LineNumberProduct])
                    
                    if len(list_Profile)==0:
                        list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
                    else:
                        exist=0
                        for item in list_Profile:
                            if Profile==item[1] and MaterialName==item[2]:
                                exist = 1
                        if exist == 0:
                            list_Profile.append([len(list_Profile)+1,Profile,MaterialName])
    
    
    conn = pyodbc.connect(r'Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=D:\IFC reader\IFC Work (main)-code\Code\test9- OTOpy OPTm - tekla - shape in IFC2 - scenario for stock - change number of material and initial - change case study\testTekla.accdb;')
    
    cursor = conn.cursor()
    #####Barasie vojod yek table QTOWithoutTimeLine dar database
    try:
        cursor.execute('select * from QTOWithoutTimeLine')
        conn.commit()
        QTOWithoutTimeLine_exists = True
    except:
        QTOWithoutTimeLine_exists = False
    ######################################################

    #####ijade table agar vojod nadashte bashe va darsorat vojod etelat pak shavad    
    if QTOWithoutTimeLine_exists== True:
        cursor.execute(''' DELETE FROM QTOWithoutTimeLine ''')
        conn.commit()
    elif QTOWithoutTimeLine_exists== False:
        cursor.execute("""CREATE TABLE QTOWithoutTimeLine (
                     Num INTEGER,
                     ElementRelated LONGTEXT,
                     IfcGuid LONGTEXT,
                     Profile LONGTEXT,
                     MinX double,
                     MinY double,
                     MinZ double,
                     UnitCoordination LONGTEXT,
                     Orientation LONGTEXT,
                     IDProduct double,
                     Material LONGTEXT,
                     Length double,
                     UnitLength LONGTEXT,
                     AreaInPlateORSurfaceArea double,
                     UnitArea LONGTEXT,
                     Volume double,
                     UnitVol LONGTEXT
                     );""")
        conn.commit()

    ######################################################
    #####update data mojod dar table QTO
    #product_information=[0Element_Name,1IfcGuid,2Profile,3X,4Y,5Z,6orientation,7MatName,8[Length[0]*pav,"METRE"],9Area,10Volume,11LineNumberProduct])
    i=0
    for ElementData in product_information:
        i = i+1
        paramet = [i,ElementData[0],ElementData[1],ElementData[2],ElementData[3],ElementData[4],ElementData[5],LengthUint,ElementData[6],ElementData[7][0],ElementData[7][1],ElementData[8][0],ElementData[8][1],ElementData[9][0],ElementData[9][1],ElementData[10][0],ElementData[10][1]]
        cursor.execute(""" INSERT INTO QTOWithoutTimeLine (Num, ElementRelated, IfcGuid, Profile, MinX, MinY, MinZ, UnitCoordination, Orientation, IDProduct, Material, Length, UnitLength, AreaInPlateORSurfaceArea, UnitArea, Volume, UnitVol)
                    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""", paramet)
        conn.commit()
    
    
    ######################################################        
    try:
        cursor.execute('select * from ProfileList')
        conn.commit()
        Profile_exists = True
    except:
        Profile_exists = False
  
     
    if Profile_exists== True:
        cursor.execute(''' DELETE FROM ProfileList ''')
        conn.commit()
    elif Profile_exists== False:
        cursor.execute("""CREATE TABLE ProfileList (
                     ID INTEGER,
                     Profile LONGTEXT,
                     Material LONGTEXT
                     );""")
        conn.commit()
    
    for item in list_Profile:
        paramet = [item[0],item[1],item[2]]
        cursor.execute(""" INSERT INTO ProfileList (ID, Profile, Material)
                    values (?, ?, ?)""", paramet)
        conn.commit()
    
    return product_information

    ######################################################        
   
def QuantityInEachZone():
    
    ###list material hayi ke morede niaz hast#####
    selected_material =[]
    conn = pyodbc.connect(r'Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=D:\IFC reader\IFC Work (main)-code\Code\test9- OTOpy OPTm - tekla - shape in IFC2 - scenario for stock - change number of material and initial - change case study\testTekla.accdb;')
    cursor = conn.cursor()
    cursor.execute('select * from tblMaterialData')
    for RowInAccess in cursor.fetchall():
        selected_material.append([RowInAccess[0],RowInAccess[1],RowInAccess[2]])
    QuntityInZone = []
 
    ###zone detials
    Zone_Detial=[]
    ElementInZone=[]
    cursor.execute('select * from tblZoneDetails')
    for RowInAccess in cursor.fetchall():
        Zone_Detial.append([RowInAccess[0],RowInAccess[1],RowInAccess[2],RowInAccess[3],RowInAccess[4],RowInAccess[5],RowInAccess[6],RowInAccess[7],RowInAccess[8],RowInAccess[9],RowInAccess[10],RowInAccess[11]])
    conn.commit()
    #product_information=[0Element_Name,1IfcGuid,2Profile,3X,4Y,5Z,6orientation,7MatName,8[Length[0]*pav,"METRE"],9Area,10Volume])
   
    for zone in Zone_Detial:
        for material in selected_material:
            QL=0
            QV=0
            QA=0
            temp_num=0
            for element in product_information:
                if zone[11] == LengthUint:
                    p=1
                elif zone[11]=="MILLIMETRE" and LengthUint=="CENTIMETRE":
                    p=10
                elif zone[11]=="MILLIMETRE" and LengthUint=="METRE":
                    p=1000
                elif zone[11]=="CENTIMETRE" and LengthUint=="METRE":
                    p=100
                elif zone[11]=="METRE" and LengthUint=="CENTIMETRE":
                    p=0.01
                elif zone[11]=="METRE" and LengthUint=="MILLIMETRE":
                    p=0.001
                if p*element[3]>=zone[5] and p*element[3]<=zone[8] and p*element[4]>=zone[6] and p*element[4]<= zone[9] and p*element[5]>=zone[7] and p*element[5]<zone[10] and zone[2]==element[6]:

                            if element[2] == "NoProfile":
                                if element[7][1] == material[1]:
                                    QL = QL + 0
                                    QV = QV + element[10][0]
                                    if element[9][0] !=0:
                                        temp_num = temp_num+ 1
                                        QA = QA+element[9][0]
                                    
                                else:
                                    QL = QL + 0
                                    QV = QV + 0
                                    QA = QA + 0
 
                            else:
                                if element[7][1] == material[1] and element[2] == material[2]:
                                    QL = QL+ element[8][0]
                                    QV = QV + element[10][0]
                                    if element[2][0:2]=="PL":
                                        QA = QA + element[9][0]
                                    else:
                                        if element[9][0]!=0:
                                            temp_num = temp_num+ 1
                                            QA = QA+element[9][0]
                                        
                                else:
                                    QL = QL + 0
                                    QV = QV + 0
                                    QA = QA + 0                  
                
            if temp_num!=0:
                QuntityInZone.append([zone[0],material[0],material[2],round(QL,3),"METRE",round(QA/temp_num,5),"SQUARE_METRE",round(QV,5),"CUBIC_METRE",zone[4],zone[3]])
            else:
                QuntityInZone.append([zone[0],material[0],material[2],round(QL,3),"METRE",round(QA,5),"SQUARE_METRE",round(QV,5),"CUBIC_METRE",zone[4],zone[3]])
    
    for zone in Zone_Detial:
        for element in product_information:
                if zone[11] == LengthUint:
                    p=1
                elif zone[11] == "MILLIMETRE" and LengthUint == "CENTIMETRE":
                    p=10
                elif zone[11] == "MILLIMETRE" and LengthUint == "METRE":
                    p=1000
                elif zone[11] == "CENTIMETRE" and LengthUint == "METRE":
                    p=100
                elif zone[11] == "METRE" and LengthUint == "CENTIMETRE":
                    p=0.01
                elif zone[11] == "METRE" and LengthUint == "MILLIMETRE":
                    p=0.001
                if p*element[3]>=zone[5] and p*element[3]<=zone[8] and p*element[4]>=zone[6] and p*element[4]<=zone[9] and p*element[5]>=zone[7] and p*element[5]<zone[10] and zone[2]==element[6]:
                    ElementInZone.append([zone[0],element[0],element[1],element[11]])                
                                    
    ####11#Barasie vojod yek table QTOforZones dar database
    try:
        cursor.execute('select * from QTOforZones')
        conn.commit()
        QTOZone_exists = True
    except:
        QTOZone_exists = False
    ######################################################
    
    ##IFCinZone ---- [IDzone,ElementName,IFCguid]
    if QTOZone_exists== True:
        cursor.execute(''' DELETE FROM QTOforZones ''')
        conn.commit()
    elif QTOZone_exists== False:
        cursor.execute("""CREATE TABLE QTOforZones (
                     IDZone INTEGER,
                     IDMaterial INTEGER,
                     MaterialName LONGTEXT,
                     TotalLengthConsumption double,
                     DailyLengthConsumption double,
                     LengthUnit LONGTEXT,
                     ProfileSurfaceAreaORTotalAreaPLATECounsumption double,
                     AreaUnit LONGTEXT,
                     TotalVolumeConsumption double,
                     DailyVolumeConsumption double,
                     VolumeConsumptionUnit LONGTEXT,
                     Predecessors LONGTEXT
                     );""")
        conn.commit()

    ######################################################
    #####update data mojod dar table QTOforZones
    ##QuntityInZone ---- [IDzone,MaterialID,MatName,Length,Unit,Area,Unit,Volume,Unit,Predecessors,Duration]
    for ElementData in QuntityInZone:
            paramet = [ElementData[0],ElementData[1],ElementData[2],ElementData[3],ElementData[3]/ElementData[10],ElementData[4],ElementData[5],ElementData[6],ElementData[7],ElementData[7]/ElementData[10],ElementData[8],ElementData[9]]
            cursor.execute(""" INSERT INTO QTOforZones (IDZone, IDMaterial, MaterialName,TotalLengthConsumption,DailyLengthConsumption, LengthUnit, ProfileSurfaceAreaORTotalAreaPLATECounsumption, AreaUnit, TotalVolumeConsumption, DailyVolumeConsumption, VolumeConsumptionUnit, Predecessors)
                        values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?,?, ?)""", paramet)
            conn.commit()         

   
            
    #####Barasie vojod yek table ElementInZone dar database
    try:
        cursor.execute('select * from ElementInZone')
        conn.commit()
        ElementInZone_exists = True
    except:
        ElementInZone_exists = False
    ######################################################
    ##IFCinZone ---- [IDzone,ElementName,IFCguid]
    if ElementInZone_exists== True:
        cursor.execute(''' DELETE FROM ElementInZone ''')
        conn.commit()
    elif ElementInZone_exists== False:
        cursor.execute("""CREATE TABLE ElementInZone (
                     IDZone INTEGER,
                     ElementName LONGTEXT,
                     IFC_GUID LONGTEXT,
                     LineNumber LONGTEXT
                     );""")
        conn.commit()

    ######################################################
    #####update data mojod dar table ElementInZone

    for ElementData in ElementInZone:
            paramet = [ElementData[0],ElementData[1],ElementData[2],ElementData[3]]
            cursor.execute(""" INSERT INTO ElementInZone (IDZone, ElementName, IFC_GUID, LineNumber)
                        values (?, ?, ?, ?)""", paramet)
            conn.commit()         

    

           


def totalQTO():
    
    TotalQuantity=[]
    selected_material =[]
    conn = pyodbc.connect(r'Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=D:\IFC reader\IFC Work (main)-code\Code\test9- OTOpy OPTm - tekla - shape in IFC2 - scenario for stock - change number of material and initial - change case study\testTekla.accdb;')
    cursor = conn.cursor()
    cursor.execute('select * from tblMaterialData')
    for RowInAccess in cursor.fetchall():
        selected_material.append([RowInAccess[0],RowInAccess[1],RowInAccess[2]])

    for material in selected_material:
            QL=0
            QV=0
            QA=0
            temp_num=0
            for element in product_information:

                if element[2] == "NoProfile":
                    if element[7][1] == material[1]:
                        QL = QL + 0
                        QV = QV + element[10][0]
                        if element[9][0] != 0:
                            temp_num = temp_num+ 1
                            QA = QA+element[9][0]
                        pass
                    else:
                        QL = QL + 0
                        QV = QV + 0
                        QA = QA + 0
                        pass
                else:
                    if element[7][1] == material[1] and element[2] == material[2]:
                        QL = QL+ element[8][0]
                        QV = QV + element[10][0]
                        if element[2][0:2]=="PL":
                            QA = QA + element[9][0]
                        else:
                            if element[9][0] != 0:
                                temp_num = temp_num+ 1 
                                QA=QA+element[9][0]
                    else:
                        QL = QL + 0
                        QV = QV + 0
                        QA = QA + 0                  
                
            if temp_num!=0:
                TotalQuantity.append([material[0],round(QL,3),"METRE",round(QA/temp_num,5),"SQUARE_METRE",round(QV,5),"CUBIC_METRE"])
            else:
                TotalQuantity.append([material[0],round(QL,3),"METRE",round(QA,5),"SQUARE_METRE",round(QV,5),"CUBIC_METRE"])
    try:
        cursor.execute('select * from totalQTO')
        conn.commit()
        TQ_exists = True
    except:
        TQ_exists = False
    ######################################################
 
    if TQ_exists== True:
        cursor.execute(''' DELETE FROM totalQTO ''')
        conn.commit()
    elif TQ_exists== False:
        cursor.execute("""CREATE TABLE totalQTO (
                     IDMaterial INTEGER,
                     SurfaceArea double,
                     AreaUnit LONGTEXT,
                     TotalVol double,
                     VolumeUnit LONGTEXT
                     );""")
        conn.commit()
    for ElementData in TotalQuantity:
        paramet = [ElementData[0],ElementData[3],ElementData[4],ElementData[5],ElementData[6]]
        cursor.execute(""" INSERT INTO totalQTO (IDMaterial,SurfaceArea,AreaUnit,TotalVol,VolumeUnit)
                    values (?, ?, ?, ?, ?)""", paramet)
        conn.commit()    




QTOfromIFC()
QuantityInEachZone()
totalQTO()