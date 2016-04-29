

# Create a test runner file from a test source file.
def create_test_runner (test_file, test_runner_file)
    puts "Generating runner for #{test_file}..."
    puts "  in #{test_runner_file}"
    mkdir_p test_runner_file.pathmap("%d")

    # Parse out the test functions in the test file.
    test_functions = []
    File.foreach(test_file) do |line|
        if line.start_with?("TEST")
            test_functions << line.sub(/^TEST\s+/, '').sub(/\(.*/, '').chomp
        end
    end

    # Get the name we're we're going to give to our suite.
    suite = "sample"

    # Generate the file.
    File.open(test_runner_file, 'w') do |f|

        # Create the includes list.
        f.puts %q{#include "greatest.h"}
        f.puts

        # extern the setup and teardown functions.
        f.puts "extern void setup(void *data);"
        f.puts "extern void teardown(void *data);"
        f.puts

        # extern all of the test functions that we found.
        test_functions.each do |function|
            f.puts "extern greatest_test_res #{function}();"
        end
        f.puts

        # Create the test suite.
        f.puts "SUITE(#{suite}){"
        f.puts "    SET_SETUP(setup, 0);"
        f.puts "    SET_TEARDOWN(teardown, 0);"
        test_functions.each do |function|
            f.puts "    RUN_TEST(#{function});"
        end
        f.puts "}"
        f.puts

        # Add the defines and the main function.
        f.puts "GREATEST_MAIN_DEFS();"
        f.puts
        f.puts "int main(int argc, char **argv) {"
        f.puts "    GREATEST_MAIN_BEGIN();"
        f.puts "    RUN_SUITE(#{suite});"
        f.puts "    GREATEST_MAIN_END();"
        f.puts "}"

    end
    complile_test_runner(test_runner_file)
end

def complile_test_runner (test_runner_file)
    sh "gcc -Ivendor/greatest -c #{test_runner_file} -o #{test_runner_file.ext(".o")}"
end
