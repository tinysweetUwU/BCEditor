#import "PythonBridge.h"
#include <Python/Python.h>

static NSCondition *bceCondition;
static NSMutableArray<NSString *> *bceInputs;
static NSMutableString *bceOutput;
static BOOL bceRunning = NO;
static NSString *bceSavePath;
static dispatch_once_t bcePythonOnce;
PyMODINIT_FUNC PyInit_bcebridge(void);

static void bceEnsurePython(void) {
    dispatch_once(&bcePythonOnce, ^{
        bceCondition = [NSCondition new];
        bceInputs = [NSMutableArray new];
        bceOutput = [NSMutableString new];
        PyImport_AppendInittab("bcebridge", &PyInit_bcebridge);
        Py_Initialize();
    });
}

static NSString *bceQuote(NSString *value) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[value] options:0 error:nil];
    NSString *array = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [array substringWithRange:NSMakeRange(1, array.length - 2)];
}

static PyObject *bce_emit(PyObject *self, PyObject *args) {
    const char *text = "";
    if (!PyArg_ParseTuple(args, "s", &text)) return NULL;
    [bceCondition lock];
    [bceOutput appendString:[NSString stringWithUTF8String:text] ?: @""];
    [bceCondition unlock];
    Py_RETURN_NONE;
}

static PyObject *bce_input(PyObject *self, PyObject *args) {
    const char *prompt = "";
    PyArg_ParseTuple(args, "|s", &prompt);
    if (prompt && prompt[0]) {
        [bceCondition lock];
        [bceOutput appendString:[NSString stringWithUTF8String:prompt] ?: @""];
        [bceCondition unlock];
    }
    [bceCondition lock];
    while (bceInputs.count == 0 && bceRunning) [bceCondition wait];
    NSString *line = bceInputs.count ? bceInputs.firstObject : @"q";
    if (bceInputs.count) [bceInputs removeObjectAtIndex:0];
    [bceCondition unlock];
    return PyUnicode_FromString(line.UTF8String);
}

static PyMethodDef bceMethods[] = {
    {"emit", bce_emit, METH_VARARGS, "Send output to the iOS console."},
    {"input", bce_input, METH_VARARGS, "Wait for input from the iOS UI."},
    {NULL, NULL, 0, NULL}
};
static struct PyModuleDef bceModule = {PyModuleDef_HEAD_INIT, "bcebridge", NULL, -1, bceMethods};
PyMODINIT_FUNC PyInit_bcebridge(void) { return PyModule_Create(&bceModule); }

void BCEPythonStart(NSString *savePath) {
    bceEnsurePython();
    [bceCondition lock]; bceRunning = YES; bceSavePath = savePath; [bceInputs removeAllObjects]; [bceOutput setString:@""]; [bceCondition unlock];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        PyGILState_STATE state = PyGILState_Ensure();
        NSString *sourcePackage = [NSBundle.mainBundle pathForResource:@"bcsfe" ofType:nil] ?: @"";
        NSString *source = sourcePackage.stringByDeletingLastPathComponent;
        NSString *vendor = [NSBundle.mainBundle pathForResource:@"vendor" ofType:nil inDirectory:@"PythonRuntime"] ?: @"";
        NSString *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject ?: NSTemporaryDirectory();
        NSString *script = [NSString stringWithFormat:@"import sys,runpy,builtins; import bcebridge; sys.path[:0]=[%@,%@]; sys.argv=['bcsfe','--input-path',%@,'--data-dir',%@]; builtins.input=bcebridge.input; sys.stdout=type('O',(),{'write':staticmethod(bcebridge.emit),'flush':staticmethod(lambda:None)})(); sys.stderr=sys.stdout; runpy.run_module('bcsfe.__main__',run_name='__main__')", bceQuote(source), bceQuote(vendor), bceQuote(savePath), bceQuote(support)];
        PyRun_SimpleString(script.UTF8String);
        PyGILState_Release(state);
        [bceCondition lock]; bceRunning = NO; [bceCondition broadcast]; [bceCondition unlock];
    });
}

BOOL BCEPythonApplyAction(NSString *savePath, NSString *action, NSInteger value) {
    bceEnsurePython();
    PyGILState_STATE state = PyGILState_Ensure();
    NSString *sourcePackage = [NSBundle.mainBundle pathForResource:@"bcsfe" ofType:nil] ?: @"";
    NSString *source = sourcePackage.stringByDeletingLastPathComponent;
    NSString *vendor = [NSBundle.mainBundle pathForResource:@"vendor" ofType:nil inDirectory:@"PythonRuntime"] ?: @"";
    NSString *support = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject ?: NSTemporaryDirectory();
    NSString *script = [NSString stringWithFormat:@"import sys; sys.path[:0]=[%@,%@]; from bcsfe.ios_api import apply; apply(%@,%@,%ld)", bceQuote(source), bceQuote(vendor), bceQuote(savePath), bceQuote(action), (long)value];
    int result = PyRun_SimpleString(script.UTF8String);
    PyGILState_Release(state);
    return result == 0;
}

void BCEPythonSubmitInput(NSString *line) { [bceCondition lock]; [bceInputs addObject:line]; [bceCondition signal]; [bceCondition unlock]; }
void BCEPythonQueueInput(NSString *line) { [bceCondition lock]; [bceInputs addObject:line]; [bceCondition broadcast]; [bceCondition unlock]; }
NSString *BCEPythonDrainOutput(void) { [bceCondition lock]; NSString *value = [bceOutput copy]; [bceOutput setString:@""]; [bceCondition unlock]; return value; }
BOOL BCEPythonIsRunning(void) { [bceCondition lock]; BOOL value = bceRunning; [bceCondition unlock]; return value; }
