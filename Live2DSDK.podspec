Pod::Spec.new do |s|
  s.name             = 'Live2DSDK'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Live2DSDK.'
  s.description      = <<-DESC
    TODO: Add long description of the pod here.
  DESC
  s.homepage         = 'https://github.com/NY/Live2DSDK'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'NY' => 'nycode.jn@gmail.com' }
  s.source           = { :git => 'https://github.com/NY/Live2DSDK.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Live2DSDK/Classes/Core/Source/**/*.{h,hpp,c,cpp,tpp,m,mm}','Live2DSDK/Classes/Core/include/*.{h,hpp,tpp}'
    sp.private_header_files = 'Live2DSDK/Classes/Core/Source/**/*.{h,hpp,tpp}','Live2DSDK/Classes/Core/include/*.{h,hpp,tpp}'
    sp.ios.vendored_library = 'Live2DSDK/Classes/Core/Library/Release-iphoneos/libLive2DCubismCore.a'
    # sp.ios.vendored_library = 'Live2DSDK/Classes/Core/Library/Debug-iphonesimulator/libLive2DCubismCore.a'

    sp.libraries = 'c++'
    sp.requires_arc = false
  end

  s.subspec 'AppSource' do |sp|
    sp.source_files = 'Live2DSDK/Classes/GLES/**/*.{h,m,mm}'
    sp.public_header_files = 'Live2DSDK/Classes/GLES/Public/*.{h,hpp}'
    sp.private_header_files = 'Live2DSDK/Classes/App/Private/**/*.{h,hpp}'

    sp.libraries = 'c++'
    sp.requires_arc = false
  end
  # 在此处定义资源
  s.resources =  ['Live2DSDK/Assets/Live2DModels.bundle']

  s.frameworks = 'UIKit', 'CoreGraphics', 'Foundation', 'MetalKit', 'Metal', 'QuartzCore', 'GLKit'
  # Link to the C++ standard library
  s.libraries = 'c++'

  # Ensure C++11 or later is used
  s.pod_target_xcconfig = {
    'OTHER_CPLUSPLUSFLAGS' => '-std=c++11',            # Ensure C++11 is used
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++11',           # Specify C++11 language standard
    'OTHER_CFLAGS' => '-DDEBUG',                        # Optional: Set any preprocessor flags
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) COCOAPODS=1 CSM_TARGET_IPHONE_ES2=1 GLES_SILENCE_DEPRECATION=1',
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'NO'
  }
end
