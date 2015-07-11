//
//  v002_Model_ImporterPlugIn.m
//  v002 Model Importer
//
//  Created by vade on 9/14/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <OpenGL/CGLMacro.h>
#import <OPenGL/glu.h>      

#import "v002_Model_ImporterPlugIn.h"

#import "config.h"
#import "cimport.h"

#define	kQCPlugIn_Name				@"v002 Model Importer"
#define	kQCPlugIn_Description		@"v002 Model Importer supports a variety of plugin formats:\n\r Collada (.dae), 3ds Max 3DS (.3ds), 3ds Max ASE (.ase), Wavefront Object (.obj), Stanford Polygon Library (.ply), AutoCAD DXF (.dxf), LightWave (.lwo), Modo (.lxo), Stereolithography (.stl), AC3D (.ac), Milkshape 3D (.ms3d), TrueSpace (.cob, .scn), Valve Model (.smd,.vta), Quake I (.mdl), Quake II (.md2), Quake III (.md3), Return to Castle Wolfenstein (.mdc), Doom 3 (.md5), Biovision BVH (.bvh), CharacterStudio Motion (.csm), DirectX X (.x)., BlitzBasic 3D (.b3d)., Quick3D (.q3d,.q3s)., Ogre XML (.mesh, .xml)., Irrlicht Mesh (.irrmesh)., Irrlicht Scene (.irr)., Neutral File Format (.nff), Sense8 WorldToolKit (.nff), Object File Format (.off), PovRAY Raw (.raw), Terragen Terrain (.ter), 3D GameStudio (.mdl) and 3D GameStudio Terrain (.hmp)"

#define kv002DescriptionAddOnText @"\n\rv002 Plugins : http://v002.info\n\nCopyright:\nvade - Anton Marini.\nbangnoise - Tom Butterworth\n\n2008-2012 - Creative Commons Non Commercial Share Alike Attribution 3.0"

#define aisgl_min(x,y) (x<y?x:y)
#define aisgl_max(x,y) (y>x?y:x)

// TODO: look at 
// http://github.com/mgottschlag/CoreRender/blob/master/CoreRender/src/render/ModelRenderable.cpp
// http://github.com/mgottschlag/CoreRender/blob/master/Tools/ModelConverter/src/main.cpp
// http://sourceforge.net/mailarchive/forum.php?thread_name=414314.62490.qm%40web55207.mail.re4.yahoo.com&forum_name=assimp-discussions
// http://sourceforge.net/mailarchive/forum.php?thread_name=4AD880BD.2070704%40sio.midco.net&forum_name=assimp-discussions


// Eventual optimization: http://lists.apple.com/archives/mac-opengl/2004/Jan/msg00180.html


//TODO: 
//Fix image paths so it can go up one level and find relative paths.

static void color4_to_float4(const aiColor4D *c, float f[4])
{
	f[0] = c->r;
	f[1] = c->g;
	f[2] = c->b;
	f[3] = c->a;
}

static void set_float4(float f[4], float a, float b, float c, float d)
{
	f[0] = a;
	f[1] = b;
	f[2] = c;
	f[3] = d;
}

// Can't send color down as a pointer to aiColor4D because AI colors are ABGR.
static void Color4f(CGLContextObj cgl_ctx, const aiColor4D *color)
{
	glColor4f(color->r, color->g, color->b, color->a);
}

@implementation v002_Model_ImporterPlugIn

@dynamic inputModelPath;
@dynamic inputImage;
@dynamic inputColor;
//@dynamic inputOverrideColor;
@dynamic inputAnimation;
@dynamic inputRenderingMode;
@dynamic inputUVGenMode;
@dynamic inputTranslationX;
@dynamic inputTranslationY;
@dynamic inputTranslationZ;
@dynamic inputRotationX;
@dynamic inputRotationY;
@dynamic inputRotationZ;
@dynamic inputScaleX;
@dynamic inputScaleY;
@dynamic inputScaleZ;
@dynamic inputBlendMode;     
@dynamic inputDepthMode;
@dynamic inputCullMode;
@dynamic inputNormalizeScale;
@dynamic inputAutoCenter;
//@dynamic inputSilhouette;
//@dynamic inputSilhouetteWidth;
//@dynamic inputSilhouetteOffset;
//@dynamic inputSilhouetteColor;
@dynamic inputLoadTextures;

@dynamic inputPointSpriteImage;
@dynamic inputPointSize;
@dynamic inputAttenuatePoints;
@dynamic inputConstantAttenuation;
@dynamic inputLinearAttenuation;
@dynamic inputQuadraticAttenuation;

+ (NSDictionary*) attributes
{	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey,
            [kQCPlugIn_Description stringByAppendingString:kv002DescriptionAddOnText], QCPlugInAttributeDescriptionKey,
            kQCPlugIn_Category, @"categories", nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
    if([key isEqualToString:@"inputModelPath"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Model Path", QCPortAttributeNameKey, nil];

/*    if([key isEqualToString:@"inputModelLoadingQuality"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Model Quality", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"Realtime Fast", @"Realtime Quality", @"Max Quality", nil], QCPortAttributeMenuItemsKey,
                [NSNumber numberWithUnsignedInt:2], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithUnsignedInt:2], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];
*/
    if([key isEqualToString:@"inputImage"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Image", QCPortAttributeNameKey, nil];

	if([key isEqualToString:@"inputColor"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Tint Color", QCPortAttributeNameKey, nil];
//
//	if([key isEqualToString:@"inputOverrideColor"])
//		return [NSDictionary dictionaryWithObjectsAndKeys:@"Use Tint Color", QCPortAttributeNameKey, [NSNumber numberWithBool:FALSE], QCPortAttributeDefaultValueKey, nil];

	
    if([key isEqualToString:@"inputAnimation"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Animation ID", QCPortAttributeNameKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];
    
    if([key isEqualToString:@"inputRenderingMode"])
        return @{QCPortAttributeNameKey: @"Rendering Mode" ,
                 QCPortAttributeMenuItemsKey : @[@"Model", @"Wireframe", @"Point"],
                 QCPortAttributeDefaultValueKey : [NSNumber numberWithUnsignedInt:0],
                 QCPortAttributeMinimumValueKey : [NSNumber numberWithUnsignedInt:0],
                 QCPortAttributeMaximumValueKey : [NSNumber numberWithUnsignedInt:2],
                 };
    
    if([key isEqualToString:@"inputUVGenMode"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Texture Coordinates", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"Model", @"Object Linear", @"Eye Linear", @"Sphere Map", nil], QCPortAttributeMenuItemsKey,
                [NSNumber numberWithUnsignedInt:3], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];
    
    if([key isEqualToString:@"inputRotationX"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Rotation X", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputRotationY"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Rotation Y", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputRotationZ"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Rotation Z", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputTranslationX"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Translation X", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputTranslationY"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Translation Y", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputTranslationZ"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Translation Z", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputScaleX"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Scale X", QCPortAttributeNameKey, [NSNumber numberWithDouble:1.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputScaleY"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Scale Y", QCPortAttributeNameKey, [NSNumber numberWithDouble:1.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputScaleZ"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Scale Z", QCPortAttributeNameKey, [NSNumber numberWithDouble:1.0],QCPortAttributeDefaultValueKey, nil];

    if([key isEqualToString:@"inputBlendMode"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Blending", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"Replace", @"Over", @"Add", nil], QCPortAttributeMenuItemsKey,
                [NSNumber numberWithUnsignedInt:2], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithUnsignedInt:1], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];
    
    if([key isEqualToString:@"inputDepthMode"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Depth Testing", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"None", @"Read/Write", @"Read-Only", nil], QCPortAttributeMenuItemsKey,
                [NSNumber numberWithUnsignedInt:2], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithUnsignedInt:1], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];

    if([key isEqualToString:@"inputCullMode"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Face Culling", QCPortAttributeNameKey,
                [NSArray arrayWithObjects:@"Model", @"Front", @"Back", @"None", nil], QCPortAttributeMenuItemsKey,
                [NSNumber numberWithUnsignedInt:3], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeDefaultValueKey,
                [NSNumber numberWithUnsignedInt:0], QCPortAttributeMinimumValueKey, nil];
    
    
    if([key isEqualToString:@"inputNormalizeScale"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Auto Scale", QCPortAttributeNameKey, [NSNumber numberWithBool:YES],QCPortAttributeDefaultValueKey, nil];

    
    if([key isEqualToString:@"inputAutoCenter"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Auto Center", QCPortAttributeNameKey, [NSNumber numberWithBool:YES],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputLoadTextures"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Load Textures", QCPortAttributeNameKey, [NSNumber numberWithBool:YES],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputPointSpriteImage"])
        return [NSDictionary dictionaryWithObject:@"Point Sprite Image" forKey:QCPortAttributeNameKey];

    if([key isEqualToString:@"inputPointSize"])
        return @{QCPortAttributeNameKey : @"Point Size",
                 QCPortAttributeDefaultValueKey : @1.0,
                 QCPortAttributeMinimumValueKey : @0.1,
                 QCPortAttributeMaximumValueKey : @64.0
                 };

    if([key isEqualToString:@"inputAttenuatePoints"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Point Attenuation",QCPortAttributeNameKey, nil];
    
    if([key isEqualToString:@"inputConstantAttenuation"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Point Constant Attenuation", QCPortAttributeNameKey, [NSNumber numberWithDouble:1.0],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputLinearAttenuation"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Point Linear Attenuation", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];
    
    if([key isEqualToString:@"inputQuadraticAttenuation"])
        return [NSDictionary dictionaryWithObjectsAndKeys:@"Point Quadratic Attenuation", QCPortAttributeNameKey, [NSNumber numberWithDouble:0.0],QCPortAttributeDefaultValueKey, nil];
    

	return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
    return [NSArray arrayWithObjects:@"inputModelPath",
            /*@"inputModelLoadingQuality", */
            @"inputImage",
            @"inputAnimation",
            @"inputRenderingMode",
            @"inputGenerateUVs",
            @"inputUVGenMode",
            @"inputRotationX",
            @"inputRotationY",
            @"inputRotationZ",
            @"inputTranslationX",
            @"inputTranslationY",
            @"inputTranslationZ",
            @"inputScaleX",
            @"inputScaleY",
            @"inputScaleZ", 
            @"inputBlendMode", 
            @"inputDepthMode",
            @"inputCullMode",
            @"inputNormalizeScale",
            @"inputAutoCenter"
            @"inputPointSpriteImage",
            @"inputPointSize",
            @"inputAttenuatePoints",
            @"inputConstantAttenuation",
            @"inputLinearAttenuation",
            @"inputQuadraticAttenuation"
            , nil];
}

+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeTimeBase;
}

- (id) init
{
	if(self = [super init])
    {                
      //  // generate UUID
//        CFUUIDRef	uuidObj = CFUUIDCreate(nil);
//        CFStringRef uuid = CFUUIDCreateString(nil, uuidObj);
//        CFRelease(uuidObj);
//        NSString *result = [[NSString alloc] initWithFormat:@"%@", uuid];
//        CFRelease(uuid);
//        
//        _queue = dispatch_queue_create([result cStringUsingEncoding:NSUTF8StringEncoding], NULL);
//
//        [result release];
        
        //animationIndex = 0;
        animationTime = 0;
        usingExternalTexture = FALSE;
	}	
	return self;
}

- (void) finalize
{
    //dispatch_release(_queue);
	[super finalize];
}

- (void) dealloc
{
    //dispatch_release(_queue);
	[super dealloc];
}

@end

@implementation v002_Model_ImporterPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
    CGLContextObj cgl_ctx = [context CGLContextObj];

    // create our 1 x 1 GL_TEXTURE_2D color texture, and set its color to our
    if(!colorTextureID)
    {
        glPushAttrib(GL_TEXTURE_BIT);
        
        glGenTextures(1, &colorTextureID);
        glEnable(GL_TEXTURE_2D);
    
        glBindTexture(GL_TEXTURE_2D, colorTextureID);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F_ARB, 1, 1, 0, GL_RGBA, GL_FLOAT, NULL);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

        
        glPopAttrib();
    }
    
   	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
    CGLContextObj cgl_ctx = [context CGLContextObj];

    // delete our color texture
    if(colorTextureID)
    {
        glDeleteTextures(1, &colorTextureID);
        colorTextureID = 0;
    }
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
    CGLContextObj cgl_ctx = [context CGLContextObj];

    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);

    if([self didValueForInputKeyChange:@"inputCullMode"])
    {
        cullMode = self.inputCullMode;   
    }
    
    if([self didValueForInputKeyChange:@"inputModelPath"]) // || ![self.inputModelPath isEqualToString:[[[self class] attributesForPropertyPortWithKey:@"inputModelPath"] valueForKey:QCPortAttributeDefaultValueKey]] )
    {
        // delete the existing scene - allows us to 'unload'
        if(v002Scene)
        {
            aiReleaseImport(v002Scene);
            v002Scene = NULL;
            
            glDeleteTextures([textureDictionary count], textureIds);
            
            [textureDictionary release];
            textureDictionary = nil;
            
            free(textureIds);
            textureIds = NULL;
            
            [self deleteGLResourcesInContext:cgl_ctx];
        }
        
        NSString * path = [self.inputModelPath stringByStandardizingPath];
				
		// relative to composition ?
		if(![path hasPrefix:@"/"])
			path =  [NSString pathWithComponents:[NSArray arrayWithObjects:[[[context compositionURL] path]stringByDeletingLastPathComponent], path, nil]]; 
		
		path = [path stringByStandardizingPath];	
		
        if([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            // Load our new path.
            
            // only ever give us triangles.
			aiPropertyStore* store = aiCreatePropertyStore();
            aiSetImportPropertyInteger(store, AI_CONFIG_PP_SBP_REMOVE, aiPrimitiveType_LINE | aiPrimitiveType_POINT );
            
            NSUInteger aiPostProccesFlags = 
            aiProcess_CalcTangentSpace          | // calculate tangents and bitangents if possible
            aiProcess_GenSmoothNormals          | // generate normals if they are not specified.
            aiProcess_JoinIdenticalVertices     | // join identical vertices/ optimize indexing
            aiProcess_ValidateDataStructure     | // perform a full validation of the loader's output
            aiProcess_ImproveCacheLocality      | // improve the cache locality of the output vertices
            aiProcess_RemoveRedundantMaterials  | // remove redundant materials
            aiProcess_FindDegenerates           | // remove degenerated polygons from the import
            aiProcess_FindInvalidData           | // detect invalid model data, such as invalid normal vectors
            aiProcess_GenUVCoords               | // convert spherical, cylindrical, box and planar mapping to proper UVs
            aiProcess_TransformUVCoords         | // preprocess UV transformations (scaling, translation ...)
            aiProcess_FindInstances             | // search for instanced meshes and remove them by references to one master
            aiProcess_LimitBoneWeights          | // limit bone weights to 4 per vertex
            aiProcess_OptimizeMeshes            | // join small meshes, if possible;
            aiProcess_OptimizeGraph             | // reduce drawcalls
            aiProcess_SplitLargeMeshes          | // reduce number of triangles batched in a single mesh/drawcall
            aiProcess_SortByPType               | // splits meshes with more than one primitive type in homogeneous submeshes. 
            aiProcess_Triangulate               | // triangulate quads/polymeshes so we render one primitive type only
            aiProcess_FlipUVs                   | // for whatever reason, this is required for us. 
			aiProcess_FixInfacingNormals		| // fix unintentional back facing faces.
            0;
                        
            v002Scene = (aiScene*) aiImportFile([path cStringUsingEncoding:[NSString defaultCStringEncoding]], aiPostProccesFlags );
            
            if(v002Scene)
            {       
                textureDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
                
				if(self.inputLoadTextures)
					[self loadTexturesInContext:context withModelPath:[self.inputModelPath stringByStandardizingPath]];
                            
                [self getBoundingBoxWithMinVector:&scene_min maxVectr:&scene_max];
              
                scene_center.x = (scene_min.x + scene_max.x) / 2.0f;
                scene_center.y = (scene_min.y + scene_max.y) / 2.0f;
                scene_center.z = (scene_min.z + scene_max.z) / 2.0f;
                
                // optional normalized scaling
                normalizedScale = scene_max.x-scene_min.x;
                normalizedScale = aisgl_max(scene_max.y - scene_min.y,normalizedScale);
                normalizedScale = aisgl_max(scene_max.z - scene_min.z,normalizedScale);
                normalizedScale = 1.f / normalizedScale;
                
                if(v002Scene->HasAnimations())
                    NSLog(@"scene has %i animations", v002Scene->mNumAnimations);
                                
                // create new mesh helpers for each mesh, will populate their data later.
                modelMeshes = [[NSMutableArray alloc] initWithCapacity:v002Scene->mNumMeshes];
            
                [self createGLResourcesInContext:cgl_ctx node:v002Scene->mRootNode];
            }
            else
            {
                [context logMessage:@"Could not load file %@", path];
            }
			
			aiReleasePropertyStore(store);
			
        }
    }
            
    if(v002Scene)
    {          
        glEnable(GL_NORMALIZE);
        
        glPushMatrix();
      
        if(self.inputBlendMode == 0)
            glDisable(GL_BLEND);
        else if(self.inputBlendMode == 1)
        {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        else
        {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        }
        
        if(self.inputDepthMode == 0)
            glDisable(GL_DEPTH_TEST);
        else if(self.inputDepthMode == 1)
        {
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);
            glDepthMask(GL_TRUE);
        }
        else
        {
            glEnable(GL_DEPTH_TEST);
            glDepthMask(GL_FALSE);
        }   
        
        glTranslated(self.inputTranslationX, self.inputTranslationY, self.inputTranslationZ);
        
        // Normalize Scale
        if(self.inputNormalizeScale)
            glScaled(normalizedScale , normalizedScale, normalizedScale);
        
        glScaled(self.inputScaleX, self.inputScaleY, self.inputScaleZ);
      
        // rotate model.
        glRotated(self.inputRotationX, 1.0, 0.0, 0.0);
        glRotated(self.inputRotationY, 0.0, 1.0, 0.0);
        glRotated(self.inputRotationZ, 0.0, 0.0, 1.0);
        
        // center the model
        if(self.inputAutoCenter)
            glTranslated( -scene_center.x, -scene_center.y, -scene_center.z);    
                
        id<QCPlugInInputImageSource> image = self.inputImage; 
        if(image)
        {
            if([image lockTextureRepresentationWithColorSpace:[context colorSpace] forBounds:[image imageBounds]])
            {
                usingExternalTexture = TRUE;
                
                glActiveTexture(GL_TEXTURE0);

                [image bindTextureRepresentationToCGLContext:cgl_ctx textureUnit:GL_TEXTURE0 normalizeCoordinates:YES];
                
                if(GL_TEXTURE_2D == [image textureTarget])
                {
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); 
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);                     
                }
                else
                {
                    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
                    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
                    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); 
                    glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);                     
                }
                
                if(self.inputUVGenMode)
                {
                    glEnable(GL_TEXTURE_GEN_S);
                    glEnable(GL_TEXTURE_GEN_T);
                    
                    GLenum uvGenMode;
                    switch (self.inputUVGenMode)
                    {
                        case 1:
                            uvGenMode = GL_OBJECT_LINEAR;
                            break;
                        case 2:
                            uvGenMode = GL_EYE_LINEAR;
                            break;
                        case 3:
                            uvGenMode = GL_SPHERE_MAP;
                            break;
                        default:
                            uvGenMode = GL_OBJECT_LINEAR;
                            break;
                    }
                    
                    glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, uvGenMode);
                    glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, uvGenMode);
                    
                    // need to manually handle flipping
                    if([image textureFlipped])
                    {
                        glMatrixMode(GL_TEXTURE);
                        glPushMatrix();
                        glScalef(1.0, -1.0, 1.0);
                        glMatrixMode(GL_MODELVIEW);
                    }
                } 
                else
                {
                    glDisable(GL_TEXTURE_GEN_S);
                    glDisable(GL_TEXTURE_GEN_T);
                }
            }
        }
        else
        {
            usingExternalTexture = FALSE;
            glActiveTexture(GL_TEXTURE0);
            glEnable(GL_TEXTURE_2D);
        }
        
        if(v002Scene->HasAnimations())
        {
            NSUInteger animation = MIN(self.inputAnimation, v002Scene->mNumAnimations - 1);
            
            [self updateAnimation:animation atTime:time];
            [self updateGLResources:cgl_ctx];
        }

        const CGFloat *mcolor;
        mcolor = CGColorGetComponents(self.inputColor);
        if(mcolor)
        {
            const GLfloat fColor[4] = {(GLfloat)mcolor[0],
            (GLfloat)mcolor[1],
            (GLfloat)mcolor[2],
            (GLfloat)mcolor[3]};
            
            
            glActiveTexture(GL_TEXTURE1);
            glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, colorTextureID);
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 1, 1, GL_RGBA, GL_FLOAT, fColor);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glEnable(GL_TEXTURE_GEN_S);
            glEnable(GL_TEXTURE_GEN_T);
            glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);
            glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_OBJECT_LINEAR);

        }
        switch (self.inputRenderingMode)
        {
            case 0:
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                [self drawMeshesInContext:cgl_ctx enableMaterials:YES];
                break;
            case 1:
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
                [self drawMeshesInContext:cgl_ctx enableMaterials:YES];
                break;

            case 2:
            {
                glPolygonMode(GL_FRONT_AND_BACK, GL_POINT);
                glPointSize((GLfloat)self.inputPointSize);
                id<QCPlugInInputImageSource> sprite = self.inputPointSpriteImage;

                float coefficients[3];
                
                if(self.inputAttenuatePoints)
                {
                    coefficients[0] = self.inputConstantAttenuation;
                    coefficients[1] = self.inputLinearAttenuation;
                    coefficients[2] = self.inputQuadraticAttenuation;
                }
                else
                {
                    coefficients[0] = 1;
                    coefficients[1] = 0;
                    coefficients[2] = 0;
                }
                glPointParameterfv(GL_POINT_DISTANCE_ATTENUATION, coefficients);

                if(sprite && [sprite lockTextureRepresentationWithColorSpace:[context colorSpace] forBounds:[sprite imageBounds]])
                {
                    glActiveTexture(GL_TEXTURE2);
                    glEnable(GL_POINT_SPRITE);
                    
                    [sprite bindTextureRepresentationToCGLContext:cgl_ctx textureUnit:GL_TEXTURE2 normalizeCoordinates:YES];
                    
                    if([sprite textureTarget] == GL_TEXTURE_2D)
                        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                    
                    glTexEnvf(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);
                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
                    
//                    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
//                    //Sample RGB, multiply by previous texunit result
//                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);   //Modulate RGB with RGB
//                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_PREVIOUS);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_RGB, GL_TEXTURE);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
//                    //Sample ALPHA, multiply by previous texunit result
//                    glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);  //Modulate ALPHA with ALPHA
//                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE1_ALPHA, GL_TEXTURE);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
//                    glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                }
                // draw
                [self drawMeshesInContext:cgl_ctx enableMaterials:YES];
                
                if(sprite)
                {
                    glDisable(GL_POINT_SPRITE);
                    glTexEnvf(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_FALSE);

                    [sprite unbindTextureRepresentationFromCGLContext:cgl_ctx textureUnit:GL_TEXTURE2];
                    [sprite unlockTextureRepresentation];
                }
                
            }
                break;
        }
        
        
//        unbind our color texture id
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, 0);
        glDisable(GL_TEXTURE_GEN_S);
        glDisable(GL_TEXTURE_GEN_T);

        glActiveTexture(GL_TEXTURE0);

        
//		if(self.inputSilhouette)
//		{
//			// Draw Filled Polygons
//			glEnable(GL_CULL_FACE);
//			glPolygonMode(GL_FRONT,GL_FILL);
//			// dont draw shared edges
//			glDepthFunc(GL_LESS);
//			// draw front facing polys only
//			glCullFace(GL_BACK);
//			// draw model
//			
//			
//			[self drawMeshesInContext:cgl_ctx enableMaterials:YES];
//			
//			// Draw Lines 
//			glPolygonMode(GL_BACK,GL_LINE);
//			// Draw shared edges 
//			glDepthFunc(GL_LEQUAL);
//			// Draw back facing edges only
//			glCullFace(GL_FRONT);  
//						
//			glLineWidth(self.inputSilhouetteWidth);
//						
//			//glDisable(GL_BLEND);
//			glEnable(GL_LINE_SMOOTH);
//			
//			
//			glEnable(GL_POLYGON_OFFSET_LINE);
//			glPolygonOffset(self.inputSilhouetteOffset, 1.0);
//
//			glDisable(GL_LIGHTING);
//						
//			if(image)
//				glBindTexture([image textureTarget], 0);
//			else
//				glBindTexture(GL_TEXTURE_2D, 0);
//					
//			const CGFloat *color;
//			
//			color = CGColorGetComponents(self.inputSilhouetteColor);
//			
//			glColor4f(color[0], color[1], color[2], color[3]);
//			
//			// Draw Model
//			[self drawMeshesInContext:cgl_ctx enableMaterials:self.inputOverrideColor];
//		}
//				
//		else
        
        if(image)
        {
            if(self.inputUVGenMode)
            {
                // need to manually handle flipping
                if([image textureFlipped])
                {
                    glMatrixMode(GL_TEXTURE);
                    glPopMatrix();
                    glMatrixMode(GL_MODELVIEW);
                }
            }
            
            [image unbindTextureRepresentationFromCGLContext:cgl_ctx textureUnit:GL_TEXTURE0];
            [image unlockTextureRepresentation];
        }
        else
        {
            glBindTexture(GL_TEXTURE_2D, 0);
            glDisable(GL_TEXTURE_2D);
        }
        
        glPopMatrix();
        
    }

    glPopClientAttrib();
    glPopAttrib();
       
	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
}

#pragma mark -
#pragma mark Texture Loading
                 
- (void) loadTexturesInContext:(id <QCPlugInContext>)context withModelPath:(NSString*) modelPath
{    
    CGLContextObj cgl_ctx = [context CGLContextObj];
    
    if (v002Scene->HasTextures())
    {
        NSLog(@"Support for meshes with embedded textures is not implemented");
        return;
    }
    
    /* getTexture Filenames and Numb of Textures */
	for (unsigned int m = 0; m < v002Scene->mNumMaterials; m++)
	{		
		int texIndex = 0;
		aiReturn texFound = AI_SUCCESS;
        
		aiString path;	// filename
        
        // TODO: handle other aiTextureTypes
		while (texFound == AI_SUCCESS)
		{
			texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_DIFFUSE, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_SPECULAR, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_EMISSIVE, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_HEIGHT, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_NORMALS, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_SHININESS, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_OPACITY, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_DISPLACEMENT, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_LIGHTMAP, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_REFLECTION, texIndex, &path);
            if(texFound != AI_SUCCESS)
                texFound = v002Scene->mMaterials[m]->GetTexture(aiTextureType_UNKNOWN, texIndex, &path);
          
            if(texFound == AI_SUCCESS)
            {
                NSString* texturePath = [NSString stringWithCString:path.data encoding:[NSString defaultCStringEncoding]];
                
                // add our path to the texture and the index to our texture dictionary.
                [textureDictionary setValue:[NSNumber numberWithUnsignedInt:texIndex] forKey:texturePath];

                texIndex++;
            }
		}		
	}    
    
    textureIds = (GLuint*) malloc(sizeof(GLuint) * [textureDictionary count]); //new GLuint[ [textureDictionary count] ];
    glGenTextures([textureDictionary count], textureIds);
    
    NSLog(@"textureDictionary: %@", textureDictionary);
    
    // create our textures, populate them, and alter our textureID value for the specific textureID we create.
    
    // so we can modify while we enumerate... 
    NSDictionary *textureCopy = [textureDictionary copy];
    
    // GCD attempt.
    //dispatch_sync(_queue, ^{
    
        int i = 0;

        for(NSString* texturePath in textureCopy)
        {        
            NSString* fullTexturePath = [[[modelPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[texturePath stringByStandardizingPath]] stringByStandardizingPath];
         
            // relative to composition ?
            if(![fullTexturePath hasPrefix:@"/"])
                fullTexturePath =  [NSString pathWithComponents:[NSArray arrayWithObjects:[[[context compositionURL] path]stringByDeletingLastPathComponent], fullTexturePath, nil]]; 
            
            fullTexturePath = [fullTexturePath stringByStandardizingPath];	
            
            NSLog(@"texturePath: %@", fullTexturePath);
            
            NSImage* textureImage = [[NSImage alloc] initWithContentsOfFile:fullTexturePath];
            
            if(textureImage)
            {
                //NSLog(@"Have Texture Image");
                
                [textureImage lockFocus];
                NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, textureImage.size.width, textureImage.size.height)];
                [textureImage unlockFocus];
                                
				glPushAttrib(GL_ALL_ATTRIB_BITS);
				
                glActiveTexture(GL_TEXTURE0);
                glEnable(GL_TEXTURE_2D);
                glBindTexture(GL_TEXTURE_2D, textureIds[i]);
                //glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap pixelsWide]);
                //glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
                
                // generate mip maps
                glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
                
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR); 
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
                
                // draw into our bitmap
                int samplesPerPixel = [bitmap samplesPerPixel];
                
                if(![bitmap isPlanar] && (samplesPerPixel == 3 || samplesPerPixel == 4))
                {
                    glTexImage2D(GL_TEXTURE_2D,
                                 0,
                                 //samplesPerPixel == 4 ? GL_COMPRESSED_RGBA_S3TC_DXT3_EXT : GL_COMPRESSED_RGB_S3TC_DXT1_EXT, 
                                 samplesPerPixel == 4 ? GL_RGBA8 : GL_RGB8,
                                 [bitmap pixelsWide],
                                 [bitmap pixelsHigh],
                                 0,
                                 samplesPerPixel == 4 ? GL_RGBA : GL_RGB,
                                 GL_UNSIGNED_BYTE,
                                 [bitmap bitmapData]);
                } 
                               
				glPopAttrib();
				
                // update our dictionary to contain the proper textureID value (from out array of generated IDs)
                [textureDictionary setValue:[NSNumber numberWithUnsignedInt:textureIds[i]] forKey:texturePath];
                
                [bitmap release];
            }
            else
            {
                [textureDictionary removeObjectForKey:texturePath];
                NSLog(@"Could not Load Texture: %@, removing reference to it.", fullTexturePath);
            }
            
            [textureImage release];
            i++;
        }       
    //});

    glBindTexture(GL_TEXTURE_2D, 0);
    
    [textureCopy release];
}

- (void) getBoundingBoxWithMinVector:(aiVector3D*) min maxVectr:(aiVector3D*) max
{
	aiMatrix4x4 trafo;
	aiIdentityMatrix4(&trafo);
    
	min->x = min->y = min->z =  1e10f;
	max->x = max->y = max->z = -1e10f;
    
    [self getBoundingBoxForNode:v002Scene->mRootNode minVector:min maxVector:max matrix:&trafo];
}

- (void) getBoundingBoxForNode:(const aiNode*)nd  minVector:(aiVector3D*) min maxVector:(aiVector3D*) max matrix:(aiMatrix4x4*) trafo
{
	aiMatrix4x4 prev;
	unsigned int n = 0, t;
    
	prev = *trafo;
	aiMultiplyMatrix4(trafo,&nd->mTransformation);
    
	for (; n < nd->mNumMeshes; ++n)
    {
		const struct aiMesh* mesh = v002Scene->mMeshes[nd->mMeshes[n]];
		for (t = 0; t < mesh->mNumVertices; ++t)
        {
			aiVector3D tmp = mesh->mVertices[t];
			aiTransformVecByMatrix4(&tmp,trafo);
            
			min->x = aisgl_min(min->x,tmp.x);
			min->y = aisgl_min(min->y,tmp.y);
			min->z = aisgl_min(min->z,tmp.z);
            
			max->x = aisgl_max(max->x,tmp.x);
			max->y = aisgl_max(max->y,tmp.y);
			max->z = aisgl_max(max->z,tmp.z);
		}
	}
    
	for (n = 0; n < nd->mNumChildren; ++n) 
    {
		[self getBoundingBoxForNode:nd->mChildren[n] minVector:min maxVector:max matrix:trafo];
	}
    
	*trafo = prev;
}

#pragma mark -
#pragma mark Rendering

- (void) createGLResourcesInContext:(CGLContextObj)cgl_ctx node:(aiNode*)node
{
    
    // create OpenGL buffers and populate them based on each meshes pertinant info.
    
    //for (unsigned int i = 0; i < v002Scene->mNumMeshes; ++i)
    for(unsigned int i = 0; i < node->mNumMeshes; ++i)
    {        
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glPushClientAttrib(GL_CLIENT_ALL_ATTRIB_BITS);
        
        NSLog(@"%u", i);

        // current mesh we are introspecting
        aiMesh* mesh = v002Scene->mMeshes[node->mMeshes[i]];
//        aiMesh* mesh = v002Scene->mMeshes[i];

        // the current meshHelper we will be populating data into.
        v002MeshHelper* meshHelper = [[v002MeshHelper alloc] init];
        meshHelper.mesh = mesh;
        meshHelper.node = node;
        
        // Handle material info        
        aiMaterial* mtl = v002Scene->mMaterials[mesh->mMaterialIndex];
        
        // Textures
        int texIndex = 0;
        aiString texPath;
        
        if(AI_SUCCESS == mtl->GetTexture(aiTextureType_DIFFUSE, texIndex, &texPath))
        {
            NSString* textureKey = [NSString stringWithCString:texPath.data encoding:[NSString defaultCStringEncoding]];
            //bind texture
            NSNumber* textureNumber = (NSNumber*)[textureDictionary valueForKey:textureKey];
            
            NSLog(@"createGLResourcesInContext: have texture %i", [textureNumber unsignedIntValue]); 
            meshHelper.textureID = [textureNumber unsignedIntValue];		
        }
        else
            meshHelper.textureID = 0;
        
        // Colors
        
        aiColor4D dcolor = aiColor4D(0.8f, 0.8f, 0.8f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_DIFFUSE, &dcolor))
            [meshHelper setDiffuseColor:&dcolor];
        
        aiColor4D scolor = aiColor4D(0.0f, 0.0f, 0.0f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_SPECULAR, &scolor))
            [meshHelper setSpecularColor:&scolor];
        
        aiColor4D acolor = aiColor4D(0.2f, 0.2f, 0.2f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_AMBIENT, &acolor))
            [meshHelper setAmbientColor:&acolor];

        aiColor4D ecolor = aiColor4D(0.0f, 0.0f, 0.0f, 1.0f);
        if(AI_SUCCESS == aiGetMaterialColor(mtl, AI_MATKEY_COLOR_EMISSIVE, &ecolor))
            [meshHelper setEmissiveColor:&ecolor];
        
        // Culling
        unsigned int max = 1;
        int two_sided;
        if((AI_SUCCESS == aiGetMaterialIntegerArray(mtl, AI_MATKEY_TWOSIDED, &two_sided, &max)) && two_sided)
            [meshHelper setTwoSided:YES];
        else
            [meshHelper setTwoSided:NO];
        
        // Create a VBO for our vertices
        GLuint vhandle;
        glGenBuffers(1, &vhandle);
        
        glBindBuffer(GL_ARRAY_BUFFER, vhandle);

        if(v002Scene->HasAnimations())
            glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * mesh->mNumVertices, NULL, GL_STREAM_DRAW);
        else
            glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * mesh->mNumVertices, NULL, GL_STATIC_DRAW);

        // populate vertices
        Vertex* verts = (Vertex*)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

        for (unsigned int x = 0; x < mesh->mNumVertices; ++x)
        {
            verts->vPosition = mesh->mVertices[x];

            if (NULL == mesh->mNormals)
                verts->vNormal = aiVector3D(0.0f,0.0f,0.0f);
            else
                verts->vNormal = mesh->mNormals[x];
            
            if (mesh->HasVertexColors(0))
            {
                verts->dColorDiffuse = mesh->mColors[0][x];
            }
            else
                verts->dColorDiffuse = aiColor4D(1.0, 1.0, 1.0, 1.0);
            
            // This varies slightly form Assimp View, we support the 3rd texture component.
            if (mesh->HasTextureCoords(0))
                verts->vTextureUV = mesh->mTextureCoords[0][x];
            else
                verts->vTextureUV = aiVector3D(0.5f,0.5f, 0.0f);
  
            ++verts;
        }

        glUnmapBuffer(GL_ARRAY_BUFFER); //invalidates verts
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        // set the mesh vertex buffer handle to our new vertex buffer.
        meshHelper.vertexBuffer = vhandle;
        
        // Create Index Buffer
                
        // populate the index buffer.
        NSUInteger nidx;
        switch (mesh->mPrimitiveTypes)
        {
            case aiPrimitiveType_POINT:
                nidx = 1;break;
            case aiPrimitiveType_LINE:
                nidx = 2;break;
            case aiPrimitiveType_TRIANGLE:
                nidx = 3;break;
            default: assert(false);
        }   
        
        // create the index buffer
        GLuint ihandle;
        glGenBuffers(1, &ihandle);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ihandle);
        
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * mesh->mNumFaces * nidx, NULL, GL_STATIC_DRAW);

        unsigned int* indices = (unsigned int*)glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);
        
        // now fill the index buffer
        for (unsigned int x = 0; x < mesh->mNumFaces; ++x)
        {
            for (unsigned int a = 0; a < nidx; ++a)
            {
//                 if(mesh->mFaces[x].mNumIndices != 3)
//                     NSLog(@"whoa dont have 3 indices...");
                
                *indices++ = mesh->mFaces[x].mIndices[a];
            }
        }
        
        glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                
        // set the mesh index buffer handle to our new index buffer.
        meshHelper.indexBuffer = ihandle;
        meshHelper.numIndices = mesh->mNumFaces * nidx;
        
        //Create VAO and populate it
        GLuint vaoHandle; 
        glGenVertexArraysAPPLE(1, &vaoHandle);
        
        glBindVertexArrayAPPLE(vaoHandle);
        
        glBindBuffer(GL_ARRAY_BUFFER, meshHelper.vertexBuffer);

        glEnableClientState(GL_NORMAL_ARRAY);
        glNormalPointer(GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(12));
                
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(3, GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(24));
      
        glEnableClientState(GL_COLOR_ARRAY);
        glColorPointer(4, GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(36));
        
        //TODO: handle second texture
        
        // VertexPointer ought to come last, apparently this is some optimization, since if its set once, first, it gets fiddled with every time something else is update.
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(3, GL_FLOAT, sizeof(Vertex), 0);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, meshHelper.indexBuffer);
        
        glBindVertexArrayAPPLE(0);
        
        // save the VAO handle into our mesh helper
        meshHelper.vao = vaoHandle;
        
        // Whew, done. Save all of this shit.
        [modelMeshes addObject:meshHelper];

        [meshHelper release];
        
        glPopClientAttrib();
        glPopAttrib();
    }
    
    for(unsigned int j = 0; j < node->mNumChildren; ++j)
    {
        [self createGLResourcesInContext:cgl_ctx node:node->mChildren[j]];
    }
}

- (void) deleteGLResourcesInContext:(CGLContextObj)cgl_ctx
{    
    for(v002MeshHelper* helper in modelMeshes)
    {
        const GLuint indexBuffer = helper.indexBuffer;
        const GLuint vertexBuffer = helper.vertexBuffer;
        const GLuint normalBuffer = helper.normalBuffer;
        const GLuint vaoHandle = helper.vao;
        
        glDeleteBuffers(1, &vertexBuffer);
        glDeleteBuffers(1, &indexBuffer);
        glDeleteBuffers(1, &normalBuffer);
        glDeleteVertexArraysAPPLE(1, &vaoHandle);
                        
        helper.indexBuffer = 0;
        helper.vertexBuffer = 0;
        helper.normalBuffer = 0;
        helper.vao = 0;
    }
    
    [modelMeshes release];
    modelMeshes = nil;
}

- (void) updateAnimation:(NSUInteger)animationIndex atTime:(NSTimeInterval)time
{
    const aiAnimation* mAnim = v002Scene->mAnimations[animationIndex];

    double currentTime = fmod((double)time,  mAnim->mDuration);
    
    // calculate the transformations for each animation channel
	for( unsigned int a = 0; a < mAnim->mNumChannels; a++)
	{
		const aiNodeAnim* channel = mAnim->mChannels[a];
        
        aiNode* targetNode = v002Scene->mRootNode->FindNode(channel->mNodeName);
        
        // ******** Position *****
        aiVector3D presentPosition( 0, 0, 0);
        if( channel->mNumPositionKeys > 0)
        {
            // Look for present frame number. Search from last position if time is after the last time, else from beginning
            // Should be much quicker than always looking from start for the average use case.
            unsigned int frame = 0;// (currentTime >= lastAnimationTime) ? lastFramePositionIndex : 0;
            while( frame < channel->mNumPositionKeys - 1)
            {
                if( currentTime < channel->mPositionKeys[frame+1].mTime)
                    break;
                frame++;
            }
            
            // interpolate between this frame's value and next frame's value
            unsigned int nextFrame = (frame + 1) % channel->mNumPositionKeys;
            const aiVectorKey& key = channel->mPositionKeys[frame];
            const aiVectorKey& nextKey = channel->mPositionKeys[nextFrame];
            double diffTime = nextKey.mTime - key.mTime;
            if( diffTime < 0.0)
                diffTime += mAnim->mDuration;
            if( diffTime > 0)
            {
                float factor = float( (currentTime - key.mTime) / diffTime);
                presentPosition = key.mValue + (nextKey.mValue - key.mValue) * factor;
            } else
            {
                presentPosition = key.mValue;
            }
        }
        
        // ******** Rotation *********
        aiQuaternion presentRotation( 1, 0, 0, 0);
        if( channel->mNumRotationKeys > 0)
        {
            unsigned int frame = 0;//(currentTime >= lastAnimationTime) ? lastFrameRotationIndex : 0;
            while( frame < channel->mNumRotationKeys - 1)
            {
                if( currentTime < channel->mRotationKeys[frame+1].mTime)
                    break;
                frame++;
            }
            
            // interpolate between this frame's value and next frame's value
            unsigned int nextFrame = (frame + 1) % channel->mNumRotationKeys;
            const aiQuatKey& key = channel->mRotationKeys[frame];
            const aiQuatKey& nextKey = channel->mRotationKeys[nextFrame];
            double diffTime = nextKey.mTime - key.mTime;
            if( diffTime < 0.0)
                diffTime += mAnim->mDuration;
            if( diffTime > 0)
            {
                float factor = float( (currentTime - key.mTime) / diffTime);
                aiQuaternion::Interpolate( presentRotation, key.mValue, nextKey.mValue, factor);
            } else
            {
                presentRotation = key.mValue;
            }
        }
        
        // ******** Scaling **********
        aiVector3D presentScaling( 1, 1, 1);
        if( channel->mNumScalingKeys > 0)
        {
            unsigned int frame = 0;//(currentTime >= lastAnimationTime) ? lastFrameScaleIndex : 0;
            while( frame < channel->mNumScalingKeys - 1)
            {
                if( currentTime < channel->mScalingKeys[frame+1].mTime)
                    break;
                frame++;
            }
            
            // TODO (thom) interpolation maybe? This time maybe even logarithmic, not linear
            presentScaling = channel->mScalingKeys[frame].mValue;
        }
        
        // build a transformation matrix from it
        //aiMatrix4x4& mat = targetNode->mTransformation; //mTransforms[a];
        aiMatrix4x4 mat = aiMatrix4x4() * aiMatrix4x4(presentRotation.GetMatrix());
        mat.a1 *= presentScaling.x; mat.b1 *= presentScaling.x; mat.c1 *= presentScaling.x;
        mat.a2 *= presentScaling.y; mat.b2 *= presentScaling.y; mat.c2 *= presentScaling.y;
        mat.a3 *= presentScaling.z; mat.b3 *= presentScaling.z; mat.c3 *= presentScaling.z;
        mat.a4 = presentPosition.x; mat.b4 = presentPosition.y; mat.c4 = presentPosition.z;
        //mat.Transpose();
                
        targetNode->mTransformation = mat;
    }    
    lastAnimationTime = currentTime;
}

- (void) updateGLResources:(CGLContextObj)cgl_ctx;
{
    // update mesh position for the animation
    for(v002MeshHelper* modelMesh in modelMeshes)
    {
        // current mesh we are introspecting
        const aiMesh* mesh = modelMesh.mesh;
        
        if(mesh->HasBones())
        {
            // calculate bone matrices
            std::vector<aiMatrix4x4> boneMatrices( mesh->mNumBones);
                    
            for( size_t a = 0; a < mesh->mNumBones; ++a)
            {
                const aiBone* bone = mesh->mBones[a];
                
                // find the corresponding node by again looking recursively through the node hierarchy for the same name
                aiNode* node = v002Scene->mRootNode->FindNode(bone->mName);
                
                // start with the mesh-to-bone matrix 
                boneMatrices[a] = bone->mOffsetMatrix;
                // and now append all node transformations down the parent chain until we're back at mesh coordinates again
                const aiNode* tempNode = node;
                while( tempNode)
                {
                    // check your matrix multiplication order here!!!
                    boneMatrices[a] = tempNode->mTransformation * boneMatrices[a];   
                    
                    tempNode = tempNode->mParent;
                }
            }
            
            // all using the results from the previous code snippet
            std::vector<aiVector3D> resultPos( mesh->mNumVertices); 
            std::vector<aiVector3D> resultNorm( mesh->mNumVertices);
            
            // loop through all vertex weights of all bones
            for( size_t a = 0; a < mesh->mNumBones; ++a)
            {
                const aiBone* bone = mesh->mBones[a];
                const aiMatrix4x4& posTrafo = boneMatrices[a];
                
                // 3x3 matrix, contains the bone matrix without the translation, only with rotation and possibly scaling
                aiMatrix3x3 normTrafo = aiMatrix3x3( posTrafo); 
                for( size_t b = 0; b < bone->mNumWeights; ++b)
                {
                    const aiVertexWeight& weight = bone->mWeights[b];
                    
                    size_t vertexId = weight.mVertexId; 
                    const aiVector3D& srcPos = mesh->mVertices[vertexId];
                    const aiVector3D& srcNorm = mesh->mNormals[vertexId];
                    
                    resultPos[vertexId] += weight.mWeight * (posTrafo * srcPos);
                    resultNorm[vertexId] += weight.mWeight * (normTrafo * srcNorm);
                }
            }
            
            // now upload the result position and normal along with the other vertex attributes into a dynamic vertex buffer, VBO or whatever
            glBindBuffer(GL_ARRAY_BUFFER, modelMesh.vertexBuffer);
            
            glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex) * mesh->mNumVertices, NULL, GL_STREAM_DRAW);
            
            Vertex* verts = (Vertex*)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
            
            for (unsigned int x = 0; x < mesh->mNumVertices; ++x)
            {
                //verts->vPosition = mesh->mVertices[x];
                verts->vPosition = resultPos[x];
                
                if (NULL == mesh->mNormals)
                    verts->vNormal = aiVector3D(0.0f,0.0f,0.0f);
                else
                    //verts->vNormal = mesh->mNormals[x];
                    verts->vNormal = resultNorm[x];

                if (mesh->HasVertexColors(0))
                {
                    verts->dColorDiffuse = mesh->mColors[0][x];
                }
                else
                    verts->dColorDiffuse = aiColor4D(1.0, 1.0, 1.0, 1.0);
                
                // This varies slightly form Assimp View, we support the 3rd texture component.
                if (mesh->HasTextureCoords(0))
                    verts->vTextureUV = mesh->mTextureCoords[0][x];
                else
                    verts->vTextureUV = aiVector3D(0.5f,0.5f, 0.0f);
                
                ++verts;
            }
            
            glUnmapBuffer(GL_ARRAY_BUFFER); //invalidates verts
            glBindBuffer(GL_ARRAY_BUFFER, 0);
        }
    }
}

- (void) drawMeshesInContext:(CGLContextObj)cgl_ctx enableMaterials:(BOOL)enableMat
{
    for(v002MeshHelper* helper in modelMeshes)
    {         
		if(enableMat)
		{
			float dc[4];
			float sc[4];
			float ac[4];
			float emc[4];        
			
//			glEnable(GL_COLOR_MATERIAL);
//			
//			// Material colors and properties
//			color4_to_float4(helper.diffuseColor, dc);
//			glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, dc);
//			
//			color4_to_float4(helper.specularColor, sc);
//			glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, sc);
//			
//			color4_to_float4(helper.ambientColor, ac);
//			glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, ac);
//			
//			color4_to_float4(helper.emissiveColor, emc);
//			glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, emc);

			// Culling
			switch (cullMode)
			{
				case 0:// automatic
				{
					if(helper.twoSided)
					{
						glEnable(GL_CULL_FACE);
						glCullFace(GL_FRONT);
					}
					else 
					{
						glEnable(GL_CULL_FACE);
						glCullFace(GL_FRONT);
					}
					break;
				}
				case 1: // force
				{
					glEnable(GL_CULL_FACE);
					glCullFace(GL_FRONT);
					break;
				}
				case 2:
				{
					glEnable(GL_CULL_FACE);
					glCullFace(GL_BACK);
					break;
				}   
				case 3:
				{
					glDisable(GL_CULL_FACE);
				}
				default:
					break;
			}
		}

		if(!usingExternalTexture)
		{
			glEnable(GL_TEXTURE_2D);
			glBindTexture(GL_TEXTURE_2D, helper.textureID);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); 
		}
		
		// This binds the whole VAO, inheriting all the buffer and client state. Weeee
		glBindVertexArrayAPPLE(helper.vao);        
		
//		if(enableMat)
//			glEnableClientState(GL_COLOR_ARRAY);
//		else
//		{
//			// crude hack to get silhouette working
//			glDisableClientState(GL_COLOR_ARRAY);
//		}
		
		glPushMatrix();
		
		aiMatrix4x4 m = helper.node->mTransformation;
		aiTransposeMatrix4(&m);
		glMultMatrixf((float*)&m);
		
		glDrawElements(GL_TRIANGLES, helper.numIndices, GL_UNSIGNED_INT, 0);
		
		glPopMatrix();
	}
}

@end
