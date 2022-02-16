import _css from 'uplot/dist/uPlot.min.css'
import uPlot from 'uplot'

let ChartHook = {
  mounted() {
    console.log('mounted')
    const productId = this.el.dataset.productId;
    const event = `new-trade:${productId}`;
    const self = this;

    this.trades = []
    this.plot = new uPlot(plotOptions(), [[], []], this.el)
    this.handleEvent(event, (payload) => self.handleNewTrade(payload))
  },
  handleNewTrade(trade) {
    let price = parseFloat(trade.price)
    let timestamp = parseInt(trade.traded_at)

    this.trades.push({
      timestamp: timestamp, price: price
    })

    if (this.trades.length > 100) {
      this.trades.splice(0, 1)
    }
    this.updateChart()
  },

  updateChart() {
    let x = this.trades.map(t => t.timestamp)
    let y = this.trades.map(t => t.price)
    this.plot.setData([x, y])
  }
}

function plotOptions() {
  return {
    width: 200, height: 80,
    class: 'chart-container',
    cursor: { show: false },
    select: { show: false },
    legend: { show: false },
    scales: {},
    axes: [
      { show: false },
      { show: false }
    ],
    series: [
      {},
      {
        size: 0,
        width: 2,
        stroke: 'white',
        fill: 'rgb(45,85,150)',
      },
    ],
  }
}

export { ChartHook }
