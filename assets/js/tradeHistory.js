let TradeHistoryHook = {
  updated() {
    while (this.el.rows.length > 10) {
      this.el.deleteRow(-1);
    }
  }
}

export { TradeHistoryHook }
