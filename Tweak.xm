#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <substrate.h>
#import <dlfcn.h>

typedef void (*CCHmacType)(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data, size_t dataLength, void *macOut);
typedef int (*CCHmacUpdateType)(CCHmacContext *ctx, const void *data, size_t dataLength);
typedef int (*CCHmacInitType)(CCHmacContext *ctx, CCHmacAlgorithm algorithm, const void *key, size_t keyLength);
typedef int (*CCHmacFinalType)(void *macOut, CCHmacContext *ctx);

static CCHmacType original_CCHmac = NULL;
static CCHmacUpdateType original_CCHmacUpdate = NULL;
static CCHmacInitType original_CCHmacInit = NULL;
static CCHmacFinalType original_CCHmacFinal = NULL;

void writeLog(NSString *message) {
  NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSString *logFilePath = [documentsDirectory stringByAppendingPathComponent:@"CCHmacLogger.log"];

  // add timestamp to the log message
  NSString *logEntry = [NSString stringWithFormat:@"%@: %@\n", [NSDate date], message];

  // write to file 
  NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
  if (fileHandle) {
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
  }
  else {
    [logEntry writeToFile:logFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
  }
}

NSString* algorithmToString(CCHmacAlgorithm algorithm) {
  switch (algorithm) {
    case kCCHmacAlgMD5: return @"MD5";
    case kCCHmacAlgSHA1: return @"SHA1";
    case kCCHmacAlgSHA224: return @"SHA224";
    case kCCHmacAlgSHA256: return @"SHA256";
    case kCCHmacAlgSHA384: return @"SHA384";
    case kCCHmacAlgSHA512: return @"SHA512";
    default: return @"Unknown Algorithm";
  }
}

size_t CCHmacOutputSize(CCHmacAlgorithm algorithm) {
  switch (algorithm) {
    case kCCHmacAlgMD5: return CC_MD5_DIGEST_LENGTH;
    case kCCHmacAlgSHA1: return CC_SHA1_DIGEST_LENGTH;
    case kCCHmacAlgSHA224: return CC_SHA224_DIGEST_LENGTH;
    case kCCHmacAlgSHA256: return CC_SHA256_DIGEST_LENGTH;
    case kCCHmacAlgSHA384: return CC_SHA384_DIGEST_LENGTH;
    case kCCHmacAlgSHA512: return CC_SHA512_DIGEST_LENGTH;
    default: return 0;
  }
}

void hooked_CCHmac(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data, size_t dataLength, void *macOut) {
  original_CCHmac(algorithm, key, keyLength, data, dataLength, macOut);
  
  NSMutableString *macOutput = [NSMutableString string];
  // length of the output is determined by the algorithm
  for (size_t i = 0; i < CCHmacOutputSize(algorithm); i++) {
    [macOutput appendFormat:@"%02x", ((unsigned char *)macOut)[i]];
  }

  NSMutableString *keyString = [NSMutableString string];
  for (size_t i = 0; i < keyLength; i++) {
    [keyString appendFormat:@"%02x", ((unsigned char *)key)[i]];
  }

  NSMutableString *dataString = [NSMutableString string];
  for (size_t i = 0; i < dataLength; i++) {
    [dataString appendFormat:@"%02x", ((unsigned char *)data)[i]];
  }

  NSString *algorithmString = algorithmToString(algorithm);

  writeLog([NSString stringWithFormat:@"CCHmac called: Algorithm=%@, KeyLength=%zu, InputLength=%zu", algorithmString, keyLength, dataLength]);
  writeLog([NSString stringWithFormat:@"Key: %@", keyString]);
  writeLog([NSString stringWithFormat:@"Input: %@", dataString]);
  writeLog([NSString stringWithFormat:@"Output: %@", macOutput]);
}

int hooked_CCHmacUpdate(CCHmacContext *ctx, const void *data, size_t dataLength) {
  int result = original_CCHmacUpdate(ctx, data, dataLength);
  writeLog([NSString stringWithFormat:@"CCHmacUpdate called: InputLength=%zu", dataLength]);

  NSMutableString *dataString = [NSMutableString string];
  for (size_t i = 0; i < dataLength; i++) {
    [dataString appendFormat:@"%02x", ((unsigned char *)data)[i]];
  }
  
  writeLog([NSString stringWithFormat:@"Input: %@", dataString]);
  return result;
}

// store algorithm for use in CCHmacFinal
static CCHmacAlgorithm currentAlgorithm;

int hooked_CCHmacInit(CCHmacContext *ctx, CCHmacAlgorithm algorithm, const void *key, size_t keyLength) {
  currentAlgorithm = algorithm;

  NSString *algorithmString = algorithmToString(algorithm);
  int result = original_CCHmacInit(ctx, algorithm, key, keyLength);
  writeLog([NSString stringWithFormat:@"CCHmacInit called: Algorithm=%@, KeyLength=%zu", algorithmString, keyLength]);
  
  NSMutableString *keyString = [NSMutableString string];
  for (size_t i = 0; i < keyLength; i++) {
    [keyString appendFormat:@"%02x", ((unsigned char *)key)[i]];
  }

  writeLog([NSString stringWithFormat:@"Key: %@", keyString]);
  return result;
}

int hooked_CCHmacFinal(void *macOut, CCHmacContext *ctx) {
  int result = original_CCHmacFinal(macOut, ctx);
  writeLog(@"CCHmacFinal called");

  NSMutableString *macOutput = [NSMutableString string];
  // length of the output is determined by the algorithm
  for (size_t i = 0; i < CCHmacOutputSize(currentAlgorithm); i++) {
    [macOutput appendFormat:@"%02x", ((unsigned char *)macOut)[i]];
  }

  writeLog([NSString stringWithFormat:@"Output: %@", macOutput]);
  return result;
}

// entry point where we hook all functions
__attribute__((constructor)) static void init() {
  original_CCHmac = (CCHmacType)dlsym(RTLD_DEFAULT, "CCHmac");
  if (original_CCHmac) MSHookFunction((void *)original_CCHmac, (void *)&hooked_CCHmac, (void **)&original_CCHmac);
  else writeLog(@"Failed to find CCHmac");

  original_CCHmacUpdate = (CCHmacUpdateType)dlsym(RTLD_DEFAULT, "CCHmacUpdate");
  if (original_CCHmacUpdate) MSHookFunction((void *)original_CCHmacUpdate, (void *)&hooked_CCHmacUpdate, (void **)&original_CCHmacUpdate);
  else writeLog(@"Failed to find CCHmacUpdate");

  original_CCHmacInit = (CCHmacInitType)dlsym(RTLD_DEFAULT, "CCHmacInit");
  if (original_CCHmacInit) MSHookFunction((void *)original_CCHmacInit, (void *)&hooked_CCHmacInit, (void **)&original_CCHmacInit);
  else writeLog(@"Failed to find CCHmacInit");

  original_CCHmacFinal = (CCHmacFinalType)dlsym(RTLD_DEFAULT, "CCHmacFinal");
  if (original_CCHmacFinal) MSHookFunction((void *)original_CCHmacFinal, (void *)&hooked_CCHmacFinal, (void **)&original_CCHmacFinal);
  else writeLog(@"Failed to find CCHmacFinal");
}
