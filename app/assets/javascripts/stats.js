$(document).on("page:change", function() {
  if ($('#playerChart').length) {
    var p_id = $('#playerChartContainer').data('player-id');
    $.ajax({
      url: '/player_points_by_game/' + p_id, 
      success: function(response, rStatus, jqXHR) {

        var context = document.getElementById('playerChart').getContext('2d');

        var data = { 
          labels: response.labels,
          datasets: [
            {
              label: "Player",
              fillColor: "rgba(0,0,0,0)",
              strokeColor: "rgba(119, 179, 0, 1)",
              pointColor: "rgba(119, 179, 0, 1)",
              pointStrokeColor: "rgba(255, 255, 255, 1)",
              pointHighlightFill: "rgba(255, 255, 255, 1)",
              pointHighlightFill: "rgba(119, 179, 0, 1)",
              data: response.data 
            }
          ]
        };

        var options = { bezierCurve: false, animation: false };
        var lineChart = new Chart(context).Line(data, options);
      }
    });
  }

  $('.collapse-link').on('click', function (e) { e.preventDefault(); });
  $('.collapse').collapse({ toggle: false });
});
