import Highcharts from 'highcharts/highstock';
import darkTheme from 'highcharts/themes/dark-unica'
darkTheme(Highcharts)

let StockChartHook = {
  mounted() {
    this.trades = [];
    let initTrades = JSON.parse(this.el.dataset.initTrades)
    this.chart = Highcharts.stockChart('stockchart-container', {
      title: {
        text: this.el.dataset.productName
      },

      series: [{
        name: this.el.dataset.productName,
        data: initTrades.map(trade => ({ x: parseInt(trade.traded_at), y: parseFloat(trade.price) })),
        tooltip: {
          valueDecimals: 2
        }
      },
      {
        type: 'column',
        name: 'Volume',
        data: initTrades.map(trade => ({ x: parseInt(trade.traded_at), y: parseFloat(trade.volume) })),
        yAxis: 1
      }],


      yAxis: [{
        labels: {
          align: 'right',
          x: -3
        },
        title: {
          text: 'Price'
        },
        height: '60%',
        lineWidth: 2,
        resize: {
          enabled: true
        }
      }, {
        labels: {
          align: 'right',
          x: -3
        },
        title: {
          text: 'Volume'
        },
        top: '65%',
        height: '35%',
        offset: 0,
        lineWidth: 2
      }]
    });
  },
  updated() {
    if (this.hasValidTrade()) {
      let trade = this.getTradeFromDataset()
      this.addTrade(trade.timestamp, trade.price, trade.volume)
    }
  },
  addTrade(timestamp, price, volume) {
    this.chart.series[0].addPoint([timestamp, price]);
    this.chart.series[1].addPoint([timestamp, volume]);
  },
  getTradeFromDataset() {
    return {
      timestamp: parseInt(this.el.dataset.tradeTimestamp),
      price: parseFloat(this.el.dataset.tradePrice),
      volume: parseFloat(this.el.dataset.tradeVolume),
    }
  },
  hasValidTrade() {
    return this.el.dataset.tradeTimestamp != undefined
  }
};

export { StockChartHook }
