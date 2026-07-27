// Dialog appearance state: request type, current step, and log-in gate.

const DEFAULT_TYPE = "visit"
const REVIEW = "review"

export default class RequestState {
  constructor() {
    this.requestType = DEFAULT_TYPE
    this.step = REVIEW
    this.confirmedLogin = false
    this.loginError = false
  }

  openDialog(type) {
    this.requestType = type
    this.step = REVIEW
    this.confirmedLogin = false
    this.loginError = false
  }

  goStep(step) {
    this.step = step
    this.loginError = false
  }

  toggleLogin(checked) {
    this.confirmedLogin = checked
    if (checked) this.loginError = false
  }

  failLogin() {
    this.loginError = true
  }
}
