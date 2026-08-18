#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT void BCEPythonStart(NSString *savePath);
FOUNDATION_EXPORT void BCEPythonSubmitInput(NSString *line);
FOUNDATION_EXPORT void BCEPythonQueueInput(NSString *line);
FOUNDATION_EXPORT NSString *BCEPythonDrainOutput(void);
FOUNDATION_EXPORT BOOL BCEPythonIsRunning(void);
NS_ASSUME_NONNULL_END
