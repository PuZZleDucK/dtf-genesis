window.findContractId = function() {
$('.contracts-row').on('click', function(){
    idClick = $(this).attr("data-id");
    window.location = ROUTES.CONTRACT_PATH + "/" + idClick;
  });
};

window.findSupplierId = function() {
$('.suppliers-row').on('click', function(){
    idClick = $(this).attr("data-id");
    window.location = ROUTES.SUPPLIER_PATH + "/" + idClick;
  });
};

window.findCsrContractId = function() {
$('.contracts-row').on('click', function(){
    idClick = $(this).attr("data-id");
    window.location = ROUTES.CSR_CONTRACT_PATH + "/" + idClick;
  });
};