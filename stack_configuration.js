$scope.dateRegExp = /\d\d?\/\d\d?\/\d\d\d\d/;

$scope.newNick = function () {
    $scope.cfg.bannedNicks.push($scope.newNickname);
    $scope.newNickname = "";
    $scope.change();
};

$scope.deleteNick = function (nick) {
    var oldBannedNicks = $scope.cfg.bannedNicks;
    $scope.cfg.bannedNicks = [];
    angular.forEach(oldBannedNicks, function (n) {
        if (nick != n) $scope.cfg.bannedNicks.push(n);
    });
    $scope.change();
};

