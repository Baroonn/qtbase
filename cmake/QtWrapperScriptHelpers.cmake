# Creates and installs the following wrapper CMake scripts:
# qt-make
# qt-cmake-private
# qt-configure-module
# qt-cmake-private-install
function(qt_internal_create_wrapper_scripts)
    # Provide a convenience cmake wrapper.
    if(CMAKE_HOST_UNIX)
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-cmake.in"
                       "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake" @ONLY)
        qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake"
                   DESTINATION "${INSTALL_BINDIR}")
    else()
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-cmake.bat.in"
                       "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake.bat" @ONLY)
        qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake.bat"
                   DESTINATION "${INSTALL_BINDIR}")
    endif()

    # Provide a private convenience wrapper with options which should not be propagated via the
    # public qt-cmake wrapper e.g. CMAKE_GENERATOR.
    # These options can not be set in a toolchain file, but only on the command line.
    # These options should not be in the public wrapper, because a consumer of Qt might want to
    # build their CMake app with the Unix Makefiles generator, while Qt should be built with the
    # Ninja generator.
    # The private wrapper is more conveient for building Qt itself, because a developer doesn't need
    # to specify the same options for each qt module built.
    set(__qt_cmake_extra "-G\"${CMAKE_GENERATOR}\"")
    if(CMAKE_HOST_UNIX)
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-cmake.in"
            "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake-private" @ONLY)
    qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake-private"
               DESTINATION "${INSTALL_BINDIR}")
    else()
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-cmake.bat.in"
            "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake-private.bat" @ONLY)
    qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-cmake-private.bat"
               DESTINATION "${INSTALL_BINDIR}")
    endif()
    unset(__qt_cmake_extra)

    # Provide a script to configure Qt modules.
    if(QT_WILL_INSTALL)
        set(__relative_path_to_processconfigureargs_script
            "${__GlobalConfig_relative_path_from_bin_dir_to_cmake_config_dir}")
    else()
        file(RELATIVE_PATH __relative_path_to_processconfigureargs_script
            "${__qt_bin_dir_absolute}" "${CMAKE_CURRENT_LIST_DIR}")
    endif()
    string(APPEND __relative_path_to_processconfigureargs_script "/QtProcessConfigureArgs.cmake")
    file(TO_NATIVE_PATH "${__relative_path_to_processconfigureargs_script}"
        __relative_path_to_processconfigureargs_script)
    if(CMAKE_HOST_UNIX)
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-configure-module.in"
            "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-configure-module" @ONLY)
        qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-configure-module"
            DESTINATION "${INSTALL_BINDIR}")
    else()
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-configure-module.bat.in"
            "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-configure-module.bat" @ONLY)
        qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/qt-configure-module.bat"
            DESTINATION "${INSTALL_BINDIR}")
    endif()
    unset(__relative_path_to_processconfigureargs_script)

    # Provide a private convenience wrapper to configure and build one or more standalone tests.
    # Calling CMake directly on a Qt test project won't work because the project does not call
    # find_package(Qt...) to get all dependencies like examples do.
    # Instead a template CMakeLists.txt project is used which sets up all the necessary private bits
    # and then calls add_subdirectory on the provided project path.
    set(__qt_cmake_standalone_test_bin_name "qt-cmake-standalone-test")
    set(__qt_cmake_private_path
        "${QT_STAGING_PREFIX}/${INSTALL_BINDIR}/qt-cmake-private")
    set(__qt_cmake_standalone_test_path
        "${__build_internals_install_dir}/${__build_internals_standalone_test_template_dir}")

    if(QT_WILL_INSTALL)
        # Need to prepend the staging prefix when doing prefix builds, because the build internals
        # install dir is relative in that case..
        qt_path_join(__qt_cmake_standalone_test_path
                     "${QT_STAGING_PREFIX}"
                     "${__qt_cmake_standalone_test_path}")
    endif()
    if(CMAKE_HOST_UNIX)
        set(__qt_cmake_standalone_test_os_prelude "#!/bin/sh")
        string(PREPEND __qt_cmake_private_path "exec ")
        set(__qt_cmake_standalone_passed_args "\"$@\" -DPWD=\"$PWD\"")
    else()
        set(__qt_cmake_standalone_test_os_prelude "@echo off")
        string(APPEND __qt_cmake_standalone_test_bin_name ".bat")
        string(APPEND __qt_cmake_private_path ".bat")
        set(__qt_cmake_standalone_passed_args "%* -DPWD=\"%CD%\"")
    endif()
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/qt-cmake-standalone-test.in"
                   "${QT_BUILD_DIR}/${INSTALL_BINDIR}/${__qt_cmake_standalone_test_bin_name}")
    qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/${__qt_cmake_standalone_test_bin_name}"
               DESTINATION "${INSTALL_BINDIR}")

    # Create an installation script that the CI can use to handle installation for both
    # single and multiple configurations.
    set(__qt_cmake_install_script_name "qt-cmake-private-install.cmake")
    if(CMAKE_CONFIGURATION_TYPES)
        set(__qt_configured_configs "${CMAKE_CONFIGURATION_TYPES}")
    elseif(CMAKE_BUILD_TYPE)
        set(__qt_configured_configs "${CMAKE_BUILD_TYPE}")
    endif()
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/bin/${__qt_cmake_install_script_name}.in"
                   "${QT_BUILD_DIR}/${INSTALL_BINDIR}/${__qt_cmake_install_script_name}" @ONLY)
    qt_install(PROGRAMS "${QT_BUILD_DIR}/${INSTALL_BINDIR}/${__qt_cmake_install_script_name}"
               DESTINATION "${INSTALL_BINDIR}")
endfunction()
