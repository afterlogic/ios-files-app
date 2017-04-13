/**
 * Created by cheshire on 17.02.17.
 */
var ExtensionGetWebPageTitleJS = function() {};

ExtensionGetWebPageTitleJS.prototype = {
    run: function(arguments) {
        // Pass the baseURI of the webpage to the extension.
        arguments.completionFunction({"title": document.title,"link":document.URL});
    }
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new ExtensionGetWebPageTitleJS;