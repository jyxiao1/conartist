import { Component, Inject } from '@angular/core';
import { Router } from '@angular/router';
import { FormGroup, AbstractControl, FormControl, Validators, ValidatorFn, AsyncValidatorFn, ValidationErrors } from '@angular/forms';

import { BroadcastService } from '../broadcast/broadcast.service';
import { SignInEvent } from '../broadcast/event';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/toPromise';
import 'rxjs/add/operator/debounceTime';
import 'rxjs/add/operator/switchMap';

import { APIService } from '../api/api.service';
import template from './sign-in.component.html';
import styles from './sign-in.component.scss';

// angular plz
declare class ConFormGroup<T extends Record<string, AbstractControl>> extends FormGroup {
  get<K extends keyof T>(key: K): T[K];
  get(key: string): null;
};

type SignInForm = {
  email: FormControl;
  password: FormControl;
};
type SignUpForm = {
  email: FormControl;
  password: FormControl;
  confirmEmail: FormControl;
  confirmPassword: FormControl;
  termsAccepted: FormControl;
};

@Component({
  selector: 'con-sign-in',
  template: template,
  styles: [ styles ],
})
export class SignInComponent {
  isSignUpMode = false;
  processing = false;
  error: string | null = null;
  notification: string | null = null;

  signInForm: ConFormGroup<SignInForm>;
  signUpForm: ConFormGroup<SignUpForm>;

  constructor(
    @Inject(APIService) private api: APIService,
    @Inject(Router) private router: Router,
    @Inject(BroadcastService) private broadcast: BroadcastService,
  ) {
    this.signInForm = new FormGroup({
      email: new FormControl('', Validators.required),
      password: new FormControl('', Validators.required),
    }) as ConFormGroup<SignInForm>;

    this.signUpForm = new FormGroup({
      email: new FormControl('', Validators.required, this.mustBeNewEmail),
      password: new FormControl('', Validators.required),
      confirmEmail: new FormControl('', [Validators.required, this.mustEqual('email')]),
      confirmPassword: new FormControl('', [Validators.required, this.mustEqual('password')]),
      termsAccepted: new FormControl(false, this.mustBeChecked),
    }) as ConFormGroup<SignUpForm>;

    // one way form sync
    this.signInForm.get('email').valueChanges.forEach((email: string) => {
      this.signUpForm.patchValue({ email });
    });
    this.signInForm.get('password').valueChanges.forEach((password: string) => {
      this.signUpForm.patchValue({ password });
    });
    this.signUpForm.get('email').valueChanges.forEach((email: string) => {
      const confirm = this.signUpForm.get('confirmEmail');
      if(email !== confirm.value) {
        confirm.setErrors({ valid: false });
      } else {
        confirm.setErrors(null);
      }
    });
    this.signUpForm.get('password').valueChanges.forEach((password: string) => {
      const confirm = this.signUpForm.get('confirmPassword');
      if(password !== confirm.value) {
        confirm.setErrors({ valid: false });
      } else {
        confirm.setErrors(null);
      }
    });
  }

  toggleSignUp() {
    this.isSignUpMode = !this.isSignUpMode;
    this.error = null;
  }

  get mustBeNewEmail(): AsyncValidatorFn {
    return (c: FormControl) => {
      c.valueChanges
        .debounceTime(500)
        .switchMap(email => this.api.isUniqueEmail(email))
        .subscribe(valid => valid ? c.setErrors(null) : c.setErrors({ valid }));
      return Observable.of(null);
    }
  }

  mustEqual(field: string): ValidatorFn {
    return (c: FormControl) => {
      if(this.signUpForm && c.value !== this.signUpForm.value[field]) {
        return { valid: false };
      }
      return null;
    };
  }

  mustBeChecked(c: FormControl): ValidationErrors | null {
    return c.value ? null : { valid: false };
  }

  async processSignUp() {
    this.processing = true;
    this.error = null;
    try {
      await this.api.signUp(this.signUpForm.value.email, this.signUpForm.value.password).toPromise();
      this.isSignUpMode = false;
      this.notification = 'Account created! You can sign in now';
    } catch(error) {
      this.error = error.message;
    } finally {
      this.processing = false;
    }
  }

  async processSignIn() {
    this.processing = true;
    this.error = null;
    try {
      const token = await this.api.signIn(this.signInForm.value.email, this.signInForm.value.password).toPromise();
      localStorage.setItem('authtoken', token);
      this.broadcast.emit(new SignInEvent);
      this.router.navigate(['/dashboard']);
    } catch(error) {
      this.error = error.message;
    } finally {
      this.processing = false;
    }
  }
}
