//
//  v002_Model_ImporterPlugIn.h
//  v002 Model Importer
//
//  Created by vade on 9/14/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <OpenGL/OpenGL.h>

#include <vector>

// assimp include files. These three are usually needed.
//#import "assimp.h"
#import "postprocess.h"
#import "scene.h"
#import "vector3.h"

#import "v002ModelLoaderHelperClasses.h"


@interface v002_Model_ImporterPlugIn : QCPlugIn
{
    aiScene* v002Scene;
	aiVector3D scene_min, scene_max, scene_center;
    double normalizedScale;    
    
    // Our array of textures.
    GLuint *textureIds;
    
    // our 1px x 1px color texure we use as a tint color
    GLuint colorTextureID;
    
    // only used if we use
    NSMutableArray* modelMeshes;   
    BOOL builtBuffers;
    
    NSMutableDictionary* textureDictionary;	// Array of Dicionaries that map image filenames to textureIds      
    
    BOOL usingExternalTexture;
    
    // an attempt at threading texture loading
    //dispatch_queue_t _queue;
    
    bool hasAnimations;
    int currentAnimation;
    
    double animationTime;
    
    // for interpolating between keyframes.
    float lastAnimationTime;
    
    // Internal use
    NSUInteger cullMode;
}

@property (assign) NSString* inputModelPath;
//@property (assign) NSUInteger inputModelLoadingQuality;
@property (assign) id<QCPlugInInputImageSource> inputImage;
//@property (assign) BOOL inputOverrideColor;
@property (assign) CGColorRef inputColor;
@property (assign) NSUInteger inputAnimation;
@property (assign) NSUInteger inputRenderingMode;
@property (assign) NSUInteger inputUVGenMode;
@property (assign) double inputTranslationX;
@property (assign) double inputTranslationY;
@property (assign) double inputTranslationZ;
@property (assign) double inputRotationX;
@property (assign) double inputRotationY;
@property (assign) double inputRotationZ;
@property (assign) double inputScaleX;
@property (assign) double inputScaleY;
@property (assign) double inputScaleZ;
@property (assign) NSUInteger inputBlendMode; 
@property (assign) NSUInteger inputDepthMode;
@property (assign) NSUInteger inputCullMode;
@property (assign) BOOL inputNormalizeScale;
@property (assign) BOOL inputAutoCenter;
//@property (assign) BOOL inputSilhouette;
//@property (assign) CGColorRef inputSilhouetteColor;
//@property (assign) double inputSilhouetteWidth;
//@property (assign) double inputSilhouetteOffset;
@property (assign) BOOL inputLoadTextures;

@property (assign) id<QCPlugInInputImageSource> inputPointSpriteImage;
@property (assign) BOOL inputAttenuatePoints;
@property (assign) double inputPointSize;
@property (assign) double inputConstantAttenuation;
@property (assign) double inputLinearAttenuation;
@property (assign) double inputQuadraticAttenuation;

@end


@interface v002_Model_ImporterPlugIn (Execution)
- (void) getBoundingBoxForNode:(const struct aiNode*)nd  minVector:(aiVector3D*) min maxVector:(aiVector3D*) max matrix:(aiMatrix4x4*) trafo;
- (void) getBoundingBoxWithMinVector:(aiVector3D*) min maxVectr:(aiVector3D*) max;

#pragma mark -
#pragma mark Rendering Code

- (void) loadTexturesInContext:(id<QCPlugInContext>)context withModelPath:(NSString*) modelPath;

// for VBOS - 
- (void) createGLResourcesInContext:(CGLContextObj)cgl_ctx node:(aiNode*)node;
- (void) deleteGLResourcesInContext:(CGLContextObj)cgl_ctx;
- (void) drawMeshesInContext:(CGLContextObj)cgl_ctx enableMaterials:(BOOL)enableMat;

// Update the CPU side bones/nodes for the animation time, and ping the GL resources to reflect CPU side state
- (void) updateAnimation:(NSUInteger)animation atTime:(NSTimeInterval)time;
- (void) updateGLResources:(CGLContextObj)cgl_ctx;

@end
