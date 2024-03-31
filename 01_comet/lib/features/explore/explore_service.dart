import 'dart:io';
import 'package:comet/features/explore/explore_model.dart';
import 'package:path/path.dart' as path;

class ExploreService {
  Future<FolderModel> exploreFileSystem({
    int level = 5,
    String? pattern,
    bool dirOnly = false,
    bool showSize = false,
    bool showDate = false,
  }) async {
    final rootDir = Directory.current;
    return _exploreDirectory(
      rootDir,
      0,
      level,
      pattern,
      dirOnly,
      showSize,
      showDate,
    );
  }

  Future<FolderModel> _exploreDirectory(
    Directory directory,
    int currentDepth,
    int level,
    String? pattern,
    bool dirOnly,
    bool showSize,
    bool showDate,
  ) async {
    final subFolders = <FolderModel>[];
    final files = <FileModel>[];

    for (final entity in directory.listSync()) {
      if (entity is Directory) {
        if (_shouldIncludeEntity(
          entity,
          pattern,
        )) {
          if (currentDepth < level) {
            subFolders.add(
              await _exploreDirectory(
                entity,
                currentDepth + 1,
                level,
                pattern,
                dirOnly,
                showSize,
                showDate,
              ),
            );
          } else {
            subFolders.add(
              FolderModel(
                name: path.basename(entity.path),
                subFolders: [],
                files: [],
              ),
            );
          }
        }
      } else if (entity is File && !dirOnly) {
        if (_shouldIncludeEntity(
          entity,
          pattern,
        )) {
          final fileSize = showSize ? await entity.length() : 0;
          files.add(FileModel(
            name: path.basename(entity.path),
            size: fileSize,
            showSize: showSize,
            showDate: showDate,
            modifiedTime: entity.lastModifiedSync(),
          ));
        }
      }
    }

    return FolderModel(
      name: path.basename(directory.path),
      subFolders: subFolders,
      files: files,
    );
  }

  bool _shouldIncludeEntity(FileSystemEntity entity, String? pattern) {
    if (pattern == null || entity is Directory) {
      return true;
    }

    if (pattern.contains('*')) {
      // Handle wildcard pattern
      final regex = RegExp(r'^' + pattern.replaceAll('*', r'.*') + r'$');
      return regex.hasMatch(entity.path);
    } else {
      // Handle regular expression pattern
      return RegExp(pattern).hasMatch(entity.path);
    }
  }

  Future<String> readLibContents() async {
    final projectDir = Directory.current;
    final libDir = Directory(path.join(projectDir.path, 'lib'));

    // Check if the project has a pubspec.yaml file
    final pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      return 'This does not appear to be a Dart or Flutter project.';
    }

    final sb = StringBuffer();
    await _readDirectory(libDir, sb, projectDir.path);
    return sb.toString();
  }

  Future<void> _readDirectory(
      Directory directory, StringBuffer sb, String projectDir) async {
    for (final entity in await directory.list().toList()) {
      if (entity is Directory) {
        await _readDirectory(entity, sb, projectDir);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = path.relative(entity.path, from: projectDir);
        sb.writeln('File: $relativePath');
        sb.writeln(await entity.readAsString());
        sb.writeln();
      }
    }
  }
}
