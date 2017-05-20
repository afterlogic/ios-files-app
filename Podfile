platform :ios, "8.0"

inhibit_all_warnings!

# Uncomment this line if you're using Swift
# use_frameworks!

abstract_target 'Application' do
    
    pod 'FastEasyMapping', '~> 1.0'
    pod 'SDWebImage', '3.7.3'
    pod 'Reachability', '~> 3.2'
    pod 'BugfenderSDK', '~> 0.3'
    pod 'AFNetworking', '2.6'
    pod 'AFNetworking+AutoRetry'
    pod 'MagicalRecord','~> 2.3.0'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'CocoaLumberjack'
    pod 'SWTableViewCell', '~> 0.3.7'
    
    target 'aurorafiles' do
        pod 'MagicalRecord','~> 2.3.0'
        pod 'Reachability', '~> 3.2'
        pod 'CRMediaPickerController'
        
        
        #этот под не используется. Нужно согласовать его использование (текст и картинка-плейсхолдер для пустого датасета)
        pod 'DZNEmptyDataSet'
    end
    
    abstract_target 'Extensions' do
        pod 'LinkPreviewKit'

        target 'aurorafilesaction' do
            
        end
        
        target 'Save shortcut' do

        end
    end
    
end


target 'aurorafilesTests' do
    
end

target 'aurorafilesUITests' do
    
end


