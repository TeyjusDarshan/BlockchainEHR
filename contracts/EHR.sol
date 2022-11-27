// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

contract HealthRecordSystem{
    enum roles {NONE, PATIENT, DOCTOR, LAB}
    address private owner;

    struct file{
        string file_name; //Name of the file given during the upload of the document in the frontend
        string file_hash; //file hash using the patient public key
    }

    struct folder{
        uint[] fileIDs; //array of fileIDs
        uint last_updated;
    }

    struct ProviderFolder{
        mapping(address => string[]) files;
    }

    mapping (address => roles) private addressToRoles;
    mapping (address => folder) private patientsToFolders;
    mapping (uint => file) private fileIDMapping;
    mapping(uint => address[]) private filePermission;
    mapping(address => ProviderFolder) private ProvidersToFolders;

    uint[] fildIDs;
    

    constructor() {
        owner = msg.sender;
    }

    //util fuctions
    function removeAddressfromArray (address[] storage a, address _address) private{
        for(uint i = 0;i < a.length;i++){
            if(a[i] == _address){
                a[i] = a[a.length - 1];
                a.pop();
            }
        }
    }



    //fucntion modifiers
    modifier checkDoctor(address id){
        require(addressToRoles[id] == roles.DOCTOR);
        _;
    }
    modifier checkPatient(address id){
        require(addressToRoles[id] == roles.PATIENT);
        _;
    }
    modifier checkLab(address id){
        require(addressToRoles[id] == roles.LAB);
        _;
    }
    modifier checkDoesNotExist(address id){
        require(addressToRoles[id] == roles.NONE);
        _;
    }

    modifier checkIfExist(address id){
        require(!(addressToRoles[id] == roles.NONE));
        _;
    }

    modifier checkFileExist(uint  file_id){
        bool DoesExist = false;
        for(uint i = 0;i < fildIDs.length;i++){
            if(fildIDs[i] == file_id){
                DoesExist = true;
            }
        }
        require(DoesExist == true);
        _;
        
    }

    modifier checkAccessToFile(uint file_id, address id){
        bool hasAccess = false;
        for(uint i = 0;i < filePermission[file_id].length; i++){
            if(filePermission[file_id][i] == id){
                hasAccess = true;
            }
        }
        require(hasAccess == true);
        _;
    }

    //signup functions
    function signupPatient() public checkDoesNotExist(msg.sender){
        addressToRoles[msg.sender] = roles.PATIENT;
        patientsToFolders[msg.sender] = folder(new uint[](0), block.timestamp);
        
    }

    function signupDoctor() public checkDoesNotExist(msg.sender){
        addressToRoles[msg.sender] = roles.DOCTOR;
    }

    function signupLab() public checkDoesNotExist(msg.sender){
        addressToRoles[msg.sender] = roles.LAB;
    }


    //grant access functions
    function grantDoctorAccessToFile(address doctor_id, string memory file_hash) public checkPatient(msg.sender) checkDoctor(doctor_id) {
        //filePermission[file_id].push(doctor_id);
        ProvidersToFolders[doctor_id].files[msg.sender].push(file_hash);

    }

    function grantLabAccessToFile(address lab_id, string memory file_hash) public checkPatient(msg.sender) checkLab(lab_id) {
        //filePermission[file_id].push(lab_id);
        ProvidersToFolders[lab_id].files[msg.sender].push(file_hash);
    }

    //revoke access functions
    function revokeDoctorAccessToAllFile(address doctor_id) public checkPatient(msg.sender) checkDoctor(doctor_id) {
        //removeAddressfromArray(filePermission[file_id], doctor_id);
        ProvidersToFolders[doctor_id].files[msg.sender] = new string[](0);
    }

    function revokeLabAccessToAllFile(address lab_id) public checkPatient(msg.sender) checkLab(lab_id) {
        //removeAddressfromArray(filePermission[file_id], lab_id);
        ProvidersToFolders[lab_id].files[msg.sender] = new string[](0);
    }

    

    //file CRUD
    function addFilesbyPatient(string memory _file_name, string memory _file_hash) public checkPatient(msg.sender){
        uint  file_id = uint(keccak256(abi.encodePacked(_file_hash)));
        fileIDMapping[file_id] = file(_file_name = _file_name, _file_hash);
        patientsToFolders[msg.sender].fileIDs.push(file_id);
        patientsToFolders[msg.sender].last_updated = block.timestamp;
        filePermission[file_id].push(msg.sender);
    }

    function addFilesbyDoctor(address patient_id, string memory _file_name, string memory _file_hash_patient, string memory file_hash_doctor) public checkDoctor(msg.sender) checkPatient(patient_id){
        uint  file_id = uint(keccak256(abi.encodePacked(_file_hash_patient)));
        fileIDMapping[file_id] = file(_file_name = _file_name, _file_hash_patient);
        patientsToFolders[patient_id].fileIDs.push(file_id);
        patientsToFolders[patient_id].last_updated = block.timestamp;
        filePermission[file_id].push(patient_id);
        ProvidersToFolders[msg.sender].files[patient_id].push(file_hash_doctor);
    }

    function addFilesbyLab(address patient_id, string memory _file_name, string memory _file_hash_patient, string memory file_hash_lab) public checkLab(msg.sender) checkPatient(patient_id){
        uint file_id = uint(keccak256(abi.encodePacked(_file_hash_patient)));
        fileIDMapping[file_id] = file(_file_name = _file_name, _file_hash_patient);
        patientsToFolders[patient_id].fileIDs.push(file_id);
        patientsToFolders[patient_id].last_updated = block.timestamp;
        filePermission[file_id].push(patient_id);
        ProvidersToFolders[msg.sender].files[patient_id].push(file_hash_lab);
    }

    //accessing files

    function GetAllFilesByProivders(address patient_id) public view checkPatient(patient_id) checkIfExist(msg.sender) returns(string[] memory){
        return ProvidersToFolders[msg.sender].files[patient_id];
    }

    function GetAllFilesByPatient() public view checkPatient(msg.sender) returns(file[100] memory){
        file[100] memory allFiles;
        for(uint i = 0;i < patientsToFolders[msg.sender].fileIDs.length;i++){
            allFiles[i] = fileIDMapping[patientsToFolders[msg.sender].fileIDs[i]];
        }
        return allFiles;
    }

}

