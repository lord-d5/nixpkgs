{ lib
, fetchPypi
, fetchpatch
, buildPythonPackage
, pythonOlder
, blosc2
, bzip2
, c-blosc
, cython
, hdf5
, lzo
, numpy
, numexpr
, packaging
, sphinx
  # Test inputs
, python
, pytest
}:

buildPythonPackage rec {
  pname = "tables";
  version = "3.8.0";
  disabled = pythonOlder "3.5";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-NPP6I2bOILGPHfVzp3wdJzBs4fKkHZ+e/2IbUZLqh4g=";
  };

  nativeBuildInputs = [
    blosc2
    cython
    sphinx
  ];

  buildInputs = [
    bzip2
    c-blosc
    hdf5
    lzo
  ];
  propagatedBuildInputs = [
    blosc2
    numpy
    numexpr
    packaging  # uses packaging.version at runtime
  ];

  # When doing `make distclean`, ignore docs
  postPatch = ''
    substituteInPlace Makefile --replace "src doc" "src"
    # Force test suite to error when unittest runner fails
    substituteInPlace tables/tests/test_suite.py \
      --replace "return 0" "assert result.wasSuccessful(); return 0" \
      --replace "return 1" "assert result.wasSuccessful(); return 1"
    substituteInPlace requirements.txt \
      --replace "blosc2~=2.0.0" "blosc2"
  '';

  # Regenerate C code with Cython
  preBuild = ''
    make distclean
  '';

  setupPyBuildFlags = [
    "--hdf5=${lib.getDev hdf5}"
    "--lzo=${lib.getDev lzo}"
    "--bzip2=${lib.getDev bzip2}"
    "--blosc=${lib.getDev c-blosc}"
  ];

  nativeCheckInputs = [
    pytest
  ];

  preCheck = ''
    cd ..
  '';

  # Runs the light (yet comprehensive) subset of the test suite.
  # The whole "heavy" test suite supposedly takes ~4 hours to run.
  checkPhase = ''
    runHook preCheck
    ${python.interpreter} -m tables.tests.test_all
    runHook postCheck
  '';

  pythonImportsCheck = [ "tables" ];

  meta = with lib; {
    description = "Hierarchical datasets for Python";
    homepage = "https://www.pytables.org/";
    license = licenses.bsd2;
    maintainers = with maintainers; [ drewrisinger ];
  };
}
