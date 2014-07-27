function removeItem(array, index) {
  return array.slice(0, index).concat(array.slice(index+1, array.length))
}

$(document).on("page:change", function() {
  //Player profile page
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

  //Compare page
  if ($('#compareChart').length) {
    var context = document.getElementById('compareChart').getContext('2d');
    var colors = ["rgba(255,0,0,1)", "rgba(201,246,0,1)", "rgba(136,5,168,1)", "rgba(0,193,43,1)", "rgba(119,179,0,1)"]
    var labels = $('#compareChart').data('labels');
    var chart = new Chart(context);
    var data = {
                 labels: labels,
                 datasets: []
               };
    var options = {
                    bezierCurve: false,
                    animation: false,
                    scaleBeginAtZero: true,
                  };
    var lineChart = null;

    $(':checkbox').change(function() {
      var checkbox = this;
      if (this.checked) {
        var p_id = $(this).val();
        $.ajax({
          url: '/player_points_by_week/' + p_id,
          success: function(response, rStatus, jqXHR) {
            var color = colors[data.datasets.length % colors.length];
            $(checkbox).data('dataset', data.datasets.length);
            data.datasets.push(
              {
                label: response.name,
                fillColor: "rgba(0,0,0,0)",
                strokeColor: color,
                pointColor: color,
                pointStrokeColor: "rgba(255,255,255,1)",
                pointHighlightFill: color,
                data: response.data
              }
            );

            if(lineChart) {
              lineChart.destroy();
            }
            lineChart = chart.Line(data, options);
          }
        });
      } else {
        //remove
        data.datasets = removeItem(data.datasets, $(this).data('dataset'));

        if(lineChart) {
          lineChart.destroy();
        }
        if(data.datasets.length > 0) {
          lineChart = chart.Line(data, options);
        }
      }
    });
  }

  //Tier page
  //comment toggle
  $('.collapse-link').on('click', function (e) { e.preventDefault(); });
  $('.collapse').collapse({ toggle: false });
});
