
load 'test_runner.rb'

CONFIG = {
    :test_dir               => "test",
    :source_dir             => "src",
    :build_dir              => "build",

    # Use .exe for running on windows/Cygwin, use an empty string for Linux.
    :test_binary_extension  => ".exe",
}

# Set this to true to echo the commands to stdout.
verbose(false)

# Extract the lists of files that we're going to work with from the configured
# directories.
TEST_FILES   = FileList["#{CONFIG[:test_dir]}/**/test_*.c"]
SOURCE_FILES = FileList["#{CONFIG[:source_dir]}/**/*.c"]

# This is the path where object files go. The object files built under here
# mirror the structure of the source folder.
OBJECT_DIR = "#{CONFIG[:build_dir]}/obj"

# This is where the executable binary test files go.
BIN_DIR = "#{CONFIG[:build_dir]}/bin"

# This is where the test runners go.
RUNNER_DIR = "#{CONFIG[:build_dir]}/runners"

# For a given source file, get the corresponding object file (including the path).
def source_file_to_object_file source_file
    source_file.pathmap("#{OBJECT_DIR}/%X.o")
end

# Remove the leading test folder name and the extension. The test name the full path
# to the test (below the test folder) withoug the extenstion, and with the "test_"
# prefix removed.
def get_test_name_from_full_path test_file
    test_file.pathmap("%{^test,}d/%{^test_,}n").sub(/^\//, '') # Remove leading slash.
end

# Get the name of the test runner source file we will create for the test file.
def get_test_runner_source_file_from_test_file test_file
    test_file.pathmap("#{RUNNER_DIR}/%{^test/,}X_runnner.c")
end

# Get the name of the test runner object file we will create for the test file.
def get_test_runner_object_file_from_test_file test_file
    get_test_runner_source_file_from_test_file(test_file).ext(".o")
end

# Scan the test source file for a list of the source files under test.
def get_build_file_list_from_test test_source_file
    # For now, assume the only file under test corresponds to the test name.
    # TODO: Scan the test file for stuff to include.
    build_file_list = "#{CONFIG[:source_dir]}/#{get_test_name_from_full_path(test_source_file)}.c"
    build_file_list = source_file_to_object_file(build_file_list)
    FileList[build_file_list]
end

# Create a file task for generating an object file from a source file.
def create_compile_task source_file
    object_file = source_file_to_object_file source_file
    desc "Build #{object_file} from #{source_file}"
    file object_file => source_file do
        # Compile here
        mkdir_p object_file.pathmap("%d")
        puts "Compiling #{source_file}..."
        puts "  to #{object_file}"
        sh "gcc -c -I#{CONFIG[:source_dir]} -Ivendor/greatest #{source_file} -o #{object_file}"
    end
end

# Create a task for running a particular test file.
def create_test_task test_file

    name = get_test_name_from_full_path(test_file)

    # Scan the test source file for a list of the source files under test.
    build_file_list = get_build_file_list_from_test(test_file)

    # The full path to the corresponding test binary.
    test_binary = "#{BIN_DIR}/#{name}#{CONFIG[:test_binary_extension]}"

    # Create an executable test binary by linking together the object files for the requested source files.
    file test_binary => build_file_list do |task|
        mkdir_p test_binary.pathmap("%d")
        puts "Linking #{task.name}..."
        puts "  from #{task.sources.join(', ')}"
        sh "gcc #{task.sources.join(' ')} -o #{task.name}"
    end

    # Each test binary also depends on the object file for the test itself.
    file test_binary => source_file_to_object_file(test_file)

    # Each test binary also depends on the test runner object file for this test.
    file test_binary => get_test_runner_object_file_from_test_file(test_file)

    # Each test runner object is dependent upon it source file.
    file get_test_runner_object_file_from_test_file(test_file) => get_test_runner_source_file_from_test_file(test_file)

    desc "Test #{name}"
    task name => test_binary do | task |

        # Run the compiled test binary.
        puts "Executing test by running #{task.source}..."
        puts %x{./#{task.source}}
    end
end

# Create a test runner source file from the test file.
def create_test_runner_task test_file
    test_runner_file = get_test_runner_source_file_from_test_file(test_file)
    file test_runner_file => test_file do
        create_test_runner(test_file, test_runner_file)
    end
end

namespace :test do

    # Create a task for running each test.
    TEST_FILES.each do |file|
        create_test_task file
        create_test_runner_task file
    end

end # namespace :test

# Create file tasks for creating a corresponding object file for each source file.
SOURCE_FILES.each do |file|
    create_compile_task file
end

# Each of the test files needs to be compiled too.
TEST_FILES.each do |file|
    create_compile_task file
end

task :clean do
    rm_rf CONFIG[:build_dir]
end

task :default do

    puts
    puts "Test Files"
    puts "------------"
    puts TEST_FILES
    puts
    puts "Source Files"
    puts "------------"
    puts SOURCE_FILES
    puts
end
