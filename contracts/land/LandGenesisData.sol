pragma solidity ^0.4.24;

import "@evolutionland/common/contracts/RBACWithAdmin.sol";
import "@evolutionland/common/contracts/interfaces/ILandData.sol";

contract LandGenesisData is RBACWithAdmin, ILandData {

    /**
     * @dev mapping from token id to land resource atrribute.
     * LandResourceAttr contains attibutes of Land asset, and is encoded in type of uint256
     * consider LandResourceAttr a binary array with the index starting at 0.
     * the rightmost one is the 0th element and the leftmost one is 255th element.
     * from the right to the left:
     * LandResourceAttr[0,15] : goldrate
     * LandResourceAttr[16,31] : woodrate
     * LandResourceAttr[32,47] : waterrate
     * LandResourceAttr[48,63] : firerate
     * LandResourceAttr[64,79] : soilrate
     * LandResourceAttr[80,95] : flag // 1:reserved, 2:special 3:hasBox
     * LandResourceAttr[96,255] : not open yet
    */
    mapping(uint256 => uint256) public tokenId2Attributes;


    // event land attributions modification
    event Modified(uint indexed tokenId, uint rightAt, uint leftAt, uint newValue);

    // event batch modify resources
    event BatchModified(uint indexed tokenId, uint goldRate, uint woodRate, uint waterRate, uint fireRate, uint soilRate);


    function addLandPixel(uint256 _tokenId, uint256 _landAttribute) public onlyAdmin {
        require(_landAttribute != 0);
        require(tokenId2Attributes[_tokenId] == 0);
        tokenId2Attributes[_tokenId] = _landAttribute;
    }

    function batchAdd(uint256[] _tokenIds, uint256[] _landAttributes) public onlyAdmin {
        require(_tokenIds.length == _landAttributes.length);
        uint length = _tokenIds.length;
        for (uint i = 0; i < length; i++) {
            addLandPixel(_tokenIds[i], _landAttributes[i]);
        }
    }

    function batchModifyResources(uint _tokenId, uint _goldRate, uint _woodRate, uint _waterRate, uint _fireRate, uint _soilRate) public onlyAdmin {
        uint landInfo = tokenId2Attributes[_tokenId];
        uint afterGoldModified = _getModifyInfoFromAttributes(landInfo, 0, 15, _goldRate);
        uint afterWoodModified = _getModifyInfoFromAttributes(afterGoldModified, 16, 31, _woodRate);
        uint afterWaterModified = _getModifyInfoFromAttributes(afterWoodModified, 32, 47, _waterRate);
        uint afterFireModified = _getModifyInfoFromAttributes(afterWaterModified, 48, 63, _fireRate);
        uint afterSoilModified = _getModifyInfoFromAttributes(afterFireModified, 64, 79, _soilRate);

        tokenId2Attributes[_tokenId] = afterSoilModified;

        emit BatchModified(_tokenId, _goldRate, _woodRate, _waterRate, _fireRate, _soilRate);
    }

    function modifyAttributes(uint _tokenId, uint _right, uint _left, uint _newValue) public onlyAdmin {
        uint landInfo = tokenId2Attributes[_tokenId];
        uint newValue = _getModifyInfoFromAttributes(landInfo, _right, _left, _newValue);
        tokenId2Attributes[_tokenId] = newValue;
        emit Modified(_tokenId, _right, _left, _newValue);
    }

    function hasBox(uint256 _tokenId) public view returns (bool) {
        uint landInfo = tokenId2Attributes[_tokenId];
        uint flag = getInfoFromAttributes(landInfo, 80, 95);
        return (flag == 3);
    }

    function isReserved(uint256 _tokenId) public view returns (bool) {
        uint landInfo = tokenId2Attributes[_tokenId];
        uint flag = getInfoFromAttributes(landInfo, 80, 95);
        return (flag == 1);
    }

    function isSpecial(uint256 _tokenId) public view returns (bool) {
        uint landInfo = tokenId2Attributes[_tokenId];
        uint flag = getInfoFromAttributes(landInfo, 80, 95);
        return (flag == 2);
    }

    // get every attribute from landInfo of certain tokenId(land pixel)
    function getDetailsFromLandInfo(uint _tokenId)
    public
    view
    returns (
        uint goldRate,
        uint woodRate,
        uint waterRate,
        uint fireRate,
        uint soilRate,
        uint flag) {
        uint landInfo = tokenId2Attributes[_tokenId];
        goldRate = getInfoFromAttributes(landInfo, 0, 15);
        woodRate = getInfoFromAttributes(landInfo, 16, 31);
        waterRate = getInfoFromAttributes(landInfo, 32, 47);
        fireRate = getInfoFromAttributes(landInfo, 48, 63);
        soilRate = getInfoFromAttributes(landInfo, 64, 79);
        flag = getInfoFromAttributes(landInfo, 80, 95);
    }


    function _getModifyInfoFromAttributes(uint256 _attributes, uint _rightAt, uint _leftAt, uint _value) internal pure returns (uint) {
        uint rightReserve = (_attributes << (256 - _rightAt)) >> (256 - _rightAt);
        uint emptyTarget = (_attributes >> _leftAt) << _leftAt;
        uint newValue = _value << _rightAt;
        return (emptyTarget + newValue + rightReserve);
    }


    /**
    * @dev get specific snippet of info from _flag
    * @param _attributes - LandPixel.flag
    * @param _rightAt - where the snippet start from the right
    * @param _leftAt - where the snippet end to the left
    * for example, uint(000...010100), because of the index starting at 0.
    * the '101' part's _rightAt is 2, and _leftAt is 4.
    */
    function getInfoFromAttributes(uint256 _attributes, uint _rightAt, uint _leftAt) public pure returns (uint) {
        uint leftShift = _attributes << (255 - _leftAt);
        uint rightShift = leftShift >> (_rightAt + 255 - _leftAt);
        return rightShift;
    }

}
