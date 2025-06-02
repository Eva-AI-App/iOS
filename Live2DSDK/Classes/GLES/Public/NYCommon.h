//
//  NYCommon.h
//  Pods
//
//  Created by niyao on 3/24/25.
//

#ifndef NYCommon_h
#define NYCommon_h
#ifdef DEBUG
    #define NYLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define NYLog(fmt, ...) do {} while (0)
#endif


typedef NS_ENUM(NSUInteger, NYLDSelectTarget)
{
    NYLDSelectTargetNone,                ///< デフォルトのフレームバッファにレンダリング
    NYLDSelectTargetModelFrameBuffer,    ///< LAppModelが各自持つフレームバッファにレンダリング
    NYLDSelectTargetViewFrameBuffer,     ///< LAppViewの持つフレームバッファにレンダリング
};
#endif /* NYCommon_h */
