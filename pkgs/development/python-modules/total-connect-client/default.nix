{ lib
, buildPythonPackage
, fetchFromGitHub
, pytestCheckHook
, pythonOlder
, zeep
}:

buildPythonPackage rec {
  pname = "total-connect-client";
  version = "2021.12";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "craigjmidwinter";
    repo = "total-connect-client";
    rev = version;
    hash = "sha256-cgs6wIMSO8t8CPn6aR35sNcgfDaXDyFBldNEBOr850s=";
  };

  propagatedBuildInputs = [
    zeep
  ];

  checkInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "total_connect_client"
  ];

  meta = with lib; {
    description = "Interact with Total Connect 2 alarm systems";
    homepage = "https://github.com/craigjmidwinter/total-connect-client";
    license = licenses.mit;
    maintainers = with maintainers; [ dotlambda ];
  };
}
